# Supabase Edge Functions

本目录包含 Supabase Edge Functions，用于执行后端逻辑。

## match-scores 函数

三数之和匹配算法的实现，用于找出总和为2026的三个分数组合。

### 部署步骤

1. 安装 Supabase CLI:
```bash
npm install -g supabase
```

2. 登录 Supabase:
```bash
supabase login
```

3. 关联项目:
```bash
supabase link --project-ref your-project-ref
```

4. 部署函数:
```bash
supabase functions deploy match-scores
```

### 调用方式

#### 手动调用（前端）
```javascript
const { data, error } = await supabase.functions.invoke('match-scores')
```

#### 定时任务（推荐）

使用 pg_cron 在数据库中设置定时任务：

```sql
-- 启用 pg_cron 扩展
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 每分钟执行一次匹配
SELECT cron.schedule(
  'match-scores-job',
  '* * * * *',  -- 每分钟
  $$
  SELECT net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/match-scores',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer your-service-role-key"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);
```

或者使用外部 Cron 服务（如 cron-job.org）定时调用 Edge Function。

### 环境变量

函数运行时自动可用的环境变量：
- `SUPABASE_URL` - Supabase 项目 URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service Role Key（完全访问权限）

### 邮件通知

要启用邮件通知，需要：

1. 注册邮件服务（推荐 Resend 或 SendGrid）
2. 在 Supabase Dashboard 中设置 Secret：
   ```bash
   supabase secrets set RESEND_API_KEY=your_api_key
   ```
3. 取消 `index.ts` 中邮件发送部分的注释

### 优化建议

1. **性能优化**：对于大量数据，可以考虑分批处理
2. **防重复**：添加去重逻辑，避免重复匹配
3. **优先级**：实现更复杂的优先级策略（如VIP用户优先）
4. **通知队列**：使用消息队列异步发送邮件
