export function translateError(error) {
  if (!error) return '发生未知错误'

  const message = String(error.message || error)
  const code = error.code || error.status

  const mappings = [
    { test: /invalid login credentials/i, text: '邮箱或密码错误' },
    { test: /email not confirmed/i, text: '邮箱未验证，请先完成邮箱验证' },
    { test: /user already registered/i, text: '该邮箱已注册，请直接登录' },
    { test: /password should be at least|password.*length/i, text: '密码长度过短，请至少 6 位' },
    { test: /signup is disabled/i, text: '当前不允许注册，请稍后再试' },
    { test: /rate limit/i, text: '请求过于频繁，请稍后再试' },
    { test: /row-level security|rls/i, text: '权限不足，无法执行该操作' },
    { test: /permission denied/i, text: '权限不足，无法执行该操作' },
    { test: /jwt/i, text: '登录状态已过期，请重新登录' },
    { test: /network|failed to fetch|timeout/i, text: '网络异常，请检查网络连接' },
  ]

  const hit = mappings.find(item => item.test.test(message))
  if (hit) return hit.text

  if (code === 401) return '未授权，请先登录'
  if (code === 403) return '权限不足，无法执行该操作'
  if (code === 429) return '请求过于频繁，请稍后再试'
  if (code === 500) return '服务器异常，请稍后再试'

  return `操作失败：${message}`
}
