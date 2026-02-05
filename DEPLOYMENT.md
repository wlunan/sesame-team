# 部署指南

## 一、Supabase 配置

### 1. 创建 Supabase 项目

1. 访问 [Supabase](https://supabase.com)
2. 点击 "New Project"
3. 填写项目名称，选择数据库密码和区域
4. 等待项目创建完成

### 2. 初始化数据库

1. 在 Supabase Dashboard 左侧菜单，进入 **SQL Editor**
2. 复制 `supabase/schema.sql` 的内容
3. 粘贴到 SQL Editor 并执行
4. 复制 `supabase/functions.sql` 的内容
5. 粘贴到 SQL Editor 并执行

### 3. 配置认证

1. 进入 **Authentication** → **Settings**
2. 启用 Email Provider
3. 配置 Email Templates（可选）
4. 设置 Site URL 为你的前端域名

### 4. 获取 API 密钥

1. 进入 **Settings** → **API**
2. 复制以下信息：
   - Project URL
   - anon public key

## 二、前端部署

### 1. 本地开发

```bash
# 1. 克隆项目
git clone <your-repo>
cd supabase-demo

# 2. 安装依赖
npm install

# 3. 配置环境变量
cp .env.example .env

# 编辑 .env 文件，填入你的 Supabase 配置
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key

# 4. 启动开发服务器
npm run dev
```

访问 http://localhost:5173

### 2. 生产部署

#### 部署到 Vercel

```bash
# 1. 安装 Vercel CLI
npm install -g vercel

# 2. 登录
vercel login

# 3. 部署
vercel

# 4. 设置环境变量
vercel env add VITE_SUPABASE_URL
vercel env add VITE_SUPABASE_ANON_KEY

# 5. 重新部署
vercel --prod
```

#### 部署到 Netlify

```bash
# 1. 构建项目
npm run build

# 2. 安装 Netlify CLI
npm install -g netlify-cli

# 3. 登录
netlify login

# 4. 部署
netlify deploy --prod --dir=dist

# 5. 在 Netlify Dashboard 设置环境变量
```

## 三、Edge Function 部署

### 1. 安装 Supabase CLI

```bash
npm install -g supabase
```

### 2. 登录并关联项目

```bash
# 登录
supabase login

# 关联项目
supabase link --project-ref your-project-ref
```

### 3. 部署匹配函数

```bash
cd supabase/functions
supabase functions deploy match-scores
```

### 4. 测试函数

```bash
# 使用 curl 测试
curl -X POST 'https://your-project.supabase.co/functions/v1/match-scores' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json'
```

## 四、设置定时任务

### 方案1：使用 pg_cron（推荐）

在 Supabase SQL Editor 中执行：

```sql
-- 启用扩展
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 每分钟执行一次匹配
SELECT cron.schedule(
  'match-scores-job',
  '* * * * *',
  $$
  SELECT net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/match-scores',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer your-service-role-key"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);

-- 查看定时任务
SELECT * FROM cron.job;

-- 删除定时任务（如需要）
SELECT cron.unschedule('match-scores-job');
```

### 方案2：使用外部 Cron 服务

1. 访问 [cron-job.org](https://cron-job.org)
2. 创建免费账号
3. 添加新任务：
   - URL: `https://your-project.supabase.co/functions/v1/match-scores`
   - Method: POST
   - Headers: `Authorization: Bearer your-anon-key`
   - Schedule: 每分钟执行

## 五、配置邮件通知（可选）

### 使用 Resend

1. 注册 [Resend](https://resend.com)
2. 获取 API Key
3. 在 Supabase 设置 Secret：

```bash
supabase secrets set RESEND_API_KEY=re_xxxxx
```

4. 取消 `supabase/functions/match-scores/index.ts` 中邮件代码的注释
5. 重新部署函数

### 使用 SendGrid

类似流程，使用 SendGrid API 替换即可。

## 六、监控和维护

### 1. 查看 Edge Function 日志

在 Supabase Dashboard:
- **Functions** → **match-scores** → **Logs**

### 2. 监控数据库性能

- **Database** → **Performance**
- 查看慢查询，优化索引

### 3. 备份数据

```bash
# 使用 Supabase CLI 备份
supabase db dump -f backup.sql
```

## 七、故障排查

### 问题1：登录失败

- 检查邮箱是否已确认
- 查看 Supabase Auth Logs

### 问题2：匹配不工作

- 检查 Edge Function 是否部署成功
- 查看 Function Logs 排查错误
- 验证定时任务是否正常运行

### 问题3：RLS 策略错误

- 在 Supabase Dashboard 中检查 RLS 策略
- 确保 `schema.sql` 完整执行

## 八、性能优化建议

1. **数据库索引**：已在 `schema.sql` 中创建必要索引
2. **分页加载**：匹配记录列表实现分页
3. **缓存策略**：使用 Redis 缓存热门分数查询
4. **CDN 加速**：静态资源使用 CDN
5. **图片优化**：压缩图片资源

## 九、安全建议

1. **环境变量**：永远不要提交 `.env` 文件到 Git
2. **RLS 策略**：确保数据库 RLS 策略正确配置
3. **Rate Limiting**：在 Edge Function 中添加请求频率限制
4. **输入验证**：前端和后端都要验证用户输入
5. **HTTPS**：生产环境必须使用 HTTPS

## 十、成本估算

### Supabase 免费套餐限额

- 数据库：500MB
- 存储：1GB
- 带宽：2GB
- Edge Functions：500,000 次调用/月

### 升级建议

当数据量或流量超出免费限额时，考虑升级到 Pro 套餐（$25/月）。

---

## 需要帮助？

- Supabase 文档: https://supabase.com/docs
- Vue 3 文档: https://vuejs.org
- 项目 Issues: [GitHub Issues](your-repo/issues)
