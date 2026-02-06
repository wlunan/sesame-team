-- Supabase Edge Function: 匹配分数算法
-- 使用方法: POST /functions/v1/match-scores
-- 此函数实现三数之和等于2026的匹配算法

-- 注意：这是伪代码说明，实际 Edge Function 需要用 TypeScript/Deno 编写
-- 请参考 supabase/functions/match-scores/index.ts

/*
功能说明：
1. 获取所有 pending 状态的分数
2. 使用三数之和算法找出所有总和为2026的组合
3. 优先匹配800+分数
4. 创建匹配记录
5. 更新分数状态为 matched
6. 发送邮件通知（使用 Supabase Auth 的邮件功能）

调用方式：
- 手动调用：通过前端触发
- 定时任务：使用 pg_cron 或外部 cron 服务每分钟调用一次

示例调用：
curl -X POST 'https://your-project.supabase.co/functions/v1/match-scores' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json'
*/

-- 创建存储过程：单次匹配算法（避免重复队伍）
CREATE OR REPLACE FUNCTION find_single_match(p_user_id UUID)
RETURNS TABLE(
  match_id UUID,
  score_1 INTEGER,
  score_2 INTEGER,
  score_3 INTEGER
) AS $$
DECLARE
  target_sum INTEGER := 2026;
  rec1 RECORD;
  rec2 RECORD;
  rec3 RECORD;
  needed_score INTEGER;
  new_match_id UUID;
  user_score_id UUID;
  user_match_count INTEGER;
BEGIN
  -- 获取用户的分数记录
  SELECT id INTO user_score_id
  FROM scores
  WHERE user_id = p_user_id
  ORDER BY created_at DESC
  LIMIT 1;

  IF user_score_id IS NULL THEN
    RETURN;
  END IF;

  -- 限制同一用户最多匹配成功两次
  SELECT COUNT(*) INTO user_match_count
  FROM matches
  WHERE score_id_1 = user_score_id
     OR score_id_2 = user_score_id
     OR score_id_3 = user_score_id;

  IF user_match_count >= 2 THEN
    UPDATE scores
    SET status = 'matched'
    WHERE id = user_score_id;
    RETURN;
  END IF;

  -- 获取用户分数信息
  SELECT * INTO rec1
  FROM scores
  WHERE id = user_score_id;

  -- 查找第二个分数（排除已匹配过的组合）
  FOR rec2 IN
    SELECT * FROM scores
    WHERE status = 'pending'
    AND id != rec1.id
    AND user_id != p_user_id
    AND score <= (target_sum - rec1.score)
    ORDER BY score DESC, created_at ASC
  LOOP
    needed_score := target_sum - rec1.score - rec2.score;
    
    -- 查找第三个分数
    SELECT * INTO rec3
    FROM scores
    WHERE status = 'pending'
    AND score = needed_score
    AND id != rec1.id
    AND id != rec2.id
    AND user_id != p_user_id
    AND NOT EXISTS (
      -- 确保这个组合之前没有匹配过
      SELECT 1 FROM matches
      WHERE (score_id_1 = rec1.id AND score_id_2 = rec2.id)
         OR (score_id_1 = rec1.id AND score_id_3 = rec2.id)
         OR (score_id_2 = rec1.id AND score_id_1 = rec2.id)
         OR (score_id_2 = rec1.id AND score_id_3 = rec2.id)
         OR (score_id_3 = rec1.id AND score_id_1 = rec2.id)
         OR (score_id_3 = rec1.id AND score_id_2 = rec2.id)
    )
    LIMIT 1;
    
    IF FOUND THEN
      -- 创建匹配记录
      INSERT INTO matches (score_id_1, score_id_2, score_id_3, total)
      VALUES (rec1.id, rec2.id, rec3.id, target_sum)
      RETURNING id INTO new_match_id;

      -- 达到上限后标记为已匹配，避免继续匹配
      IF user_match_count + 1 >= 2 THEN
        UPDATE scores
        SET status = 'matched'
        WHERE id = user_score_id;
      END IF;
      
      -- 返回匹配结果
      match_id := new_match_id;
      score_1 := rec1.score;
      score_2 := rec2.score;
      score_3 := rec3.score;
      RETURN NEXT;
      
      -- 只返回一个匹配
      RETURN;
    END IF;
  END LOOP;
  
  RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 授予执行权限
GRANT EXECUTE ON FUNCTION find_single_match(UUID) TO authenticated;
