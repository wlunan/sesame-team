import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// 数据库表名常量
export const TABLES = {
  SCORES: 'scores',
  MATCHES: 'matches',
  REPORTS: 'reports'
}

// 分数状态常量
export const SCORE_STATUS = {
  PENDING: 'pending',
  MATCHED: 'matched',
  INVALID: 'invalid'
}

// 匹配状态常量
export const MATCH_STATUS = {
  ACTIVE: 'active',
  EXPIRED: 'expired',
  REPORTED: 'reported'
}
