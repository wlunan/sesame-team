-- 创建 scores 表 (分数表)
CREATE TABLE IF NOT EXISTS scores (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  score INTEGER NOT NULL CHECK (score >= 0 AND score <= 950),
  command TEXT NOT NULL,
  email TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'matched', 'invalid')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建 matches 表 (匹配记录表)
CREATE TABLE IF NOT EXISTS matches (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  score_id_1 UUID REFERENCES scores(id) ON DELETE CASCADE NOT NULL,
  score_id_2 UUID REFERENCES scores(id) ON DELETE CASCADE NOT NULL,
  score_id_3 UUID REFERENCES scores(id) ON DELETE CASCADE NOT NULL,
  total INTEGER NOT NULL CHECK (total = 2026),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'reported')),
  matched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建 reports 表 (举报表)
CREATE TABLE IF NOT EXISTS reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
  score_id UUID REFERENCES scores(id) ON DELETE CASCADE NOT NULL,
  reporter_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 兼容已有表结构的更新
ALTER TABLE reports ADD COLUMN IF NOT EXISTS score_id UUID REFERENCES scores(id) ON DELETE CASCADE;
ALTER TABLE reports ALTER COLUMN match_id DROP NOT NULL;

-- 创建 search_logs 表 (搜索记录表)
CREATE TABLE IF NOT EXISTS search_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  score INTEGER NOT NULL CHECK (score >= 0 AND score <= 950),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_scores_user_id ON scores(user_id);
CREATE INDEX IF NOT EXISTS idx_scores_status ON scores(status);
CREATE INDEX IF NOT EXISTS idx_scores_score ON scores(score);
CREATE INDEX IF NOT EXISTS idx_scores_created_at ON scores(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_matches_score_ids ON matches(score_id_1, score_id_2, score_id_3);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_reports_match_id ON reports(match_id);
CREATE INDEX IF NOT EXISTS idx_reports_score_id ON reports(score_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_reports_unique_score_reporter
  ON reports(score_id, reporter_id);
CREATE INDEX IF NOT EXISTS idx_search_logs_user_id ON search_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_search_logs_created_at ON search_logs(created_at DESC);

-- 启用 Row Level Security (RLS)
ALTER TABLE scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE search_logs ENABLE ROW LEVEL SECURITY;

-- RLS 策略：用户可以查看所有 pending 状态的分数
CREATE POLICY "Users can view pending scores"
  ON scores FOR SELECT
  USING (status = 'pending');

-- RLS 策略：认证用户可查看分数（用于显示最近记录）
CREATE POLICY "Authenticated users can view scores"
  ON scores FOR SELECT
  USING (auth.role() = 'authenticated');

-- RLS 策略：用户只能插入自己的分数
CREATE POLICY "Users can insert their own scores"
  ON scores FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS 策略：用户可以查看自己的分数
CREATE POLICY "Users can view their own scores"
  ON scores FOR SELECT
  USING (auth.uid() = user_id);

-- RLS 策略：用户可以查看与自己相关的匹配记录
CREATE POLICY "Users can view their matches"
  ON matches FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM scores 
      WHERE scores.id IN (matches.score_id_1, matches.score_id_2, matches.score_id_3)
      AND scores.user_id = auth.uid()
    )
  );

-- RLS 策略：所有认证用户可以查看匹配记录
CREATE POLICY "Authenticated users can view matches"
  ON matches FOR SELECT
  USING (auth.role() = 'authenticated');

-- RLS 策略：用户可以提交举报
CREATE POLICY "Users can insert reports"
  ON reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

-- RLS 策略：用户可以查看自己的举报
CREATE POLICY "Users can view their reports"
  ON reports FOR SELECT
  USING (auth.uid() = reporter_id);

-- RLS 策略：用户可以插入自己的搜索记录
CREATE POLICY "Users can insert their own search logs"
  ON search_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS 策略：用户可以查看自己的搜索记录
CREATE POLICY "Users can view their own search logs"
  ON search_logs FOR SELECT
  USING (auth.uid() = user_id);

-- 创建更新 updated_at 的触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为 scores 表添加更新时间触发器
CREATE TRIGGER update_scores_updated_at
  BEFORE UPDATE ON scores
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 匹配插入前校验：确保三数之和等于2026
CREATE OR REPLACE FUNCTION validate_match_sum()
RETURNS TRIGGER AS $$
DECLARE
  sum_scores INTEGER;
BEGIN
  SELECT s1.score + s2.score + s3.score INTO sum_scores
  FROM scores s1
  JOIN scores s2 ON s2.id = NEW.score_id_2
  JOIN scores s3 ON s3.id = NEW.score_id_3
  WHERE s1.id = NEW.score_id_1;

  IF sum_scores IS NULL OR sum_scores != 2026 THEN
    RAISE EXCEPTION '匹配总和不等于2026';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_matches_sum
  BEFORE INSERT ON matches
  FOR EACH ROW
  EXECUTE FUNCTION validate_match_sum();

-- 举报计数触发器：同一口令被举报>=2则标记为失效
CREATE OR REPLACE FUNCTION update_score_invalid_on_reports()
RETURNS TRIGGER AS $$
DECLARE
  report_count INTEGER;
BEGIN
  IF NEW.score_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT COUNT(*) INTO report_count
  FROM reports
  WHERE score_id = NEW.score_id;

  IF report_count >= 2 THEN
    UPDATE scores
    SET status = 'invalid'
    WHERE id = NEW.score_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_score_invalid_on_reports
  AFTER INSERT ON reports
  FOR EACH ROW
  EXECUTE FUNCTION update_score_invalid_on_reports();

-- 创建视图：用户匹配详情
CREATE OR REPLACE VIEW user_match_details AS
SELECT 
  m.id AS match_id,
  m.matched_at,
  m.status,
  s1.id AS score_id_1,
  s1.score AS score_1,
  s1.command AS command_1,
  s1.email AS email_1,
  s1.user_id AS user_id_1,
  s2.id AS score_id_2,
  s2.score AS score_2,
  s2.command AS command_2,
  s2.email AS email_2,
  s2.user_id AS user_id_2,
  s3.id AS score_id_3,
  s3.score AS score_3,
  s3.command AS command_3,
  s3.email AS email_3,
  s3.user_id AS user_id_3
FROM matches m
JOIN scores s1 ON m.score_id_1 = s1.id
JOIN scores s2 ON m.score_id_2 = s2.id
JOIN scores s3 ON m.score_id_3 = s3.id;

-- 授予视图查询权限
GRANT SELECT ON user_match_details TO authenticated;
