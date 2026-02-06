-- 更新说明：匹配逻辑优化

## 改动内容

### 1. 单次匹配函数（find_single_match）
替换原来的 `find_and_create_matches()`，新函数特点：
- 接收用户 ID 参数
- 每次只返回一个新的匹配队伍
- 自动排除已匹配过的组合（避免重复）
- 优先匹配高分（800+）

### 2. 使用方法

在 Supabase SQL Editor 执行 `supabase/functions.sql` 中的新函数定义。

### 3. 前端调用
```javascript
// 提交后自动匹配一次
await supabase.rpc('find_single_match', { p_user_id: authStore.user.id })

// 点击"再次匹配"按钮触发
await supabase.rpc('find_single_match', { p_user_id: authStore.user.id })
```

### 4. 功能说明
- 提交分数后自动触发首次匹配
- 显示"再次匹配"按钮，用户可主动寻找新队伍
- 每次匹配返回不同的队伍组合
- 搜索结果现在显示口令信息

## 部署步骤
1. 在 Supabase SQL Editor 执行更新后的 `supabase/functions.sql`
2. 前端代码已更新，重新构建部署即可
