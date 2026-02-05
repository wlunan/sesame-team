import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const session = ref(null)
  const loading = ref(false)

  const isAuthenticated = computed(() => !!user.value)

  // 初始化：检查当前会话
  async function initialize() {
    loading.value = true
    try {
      const { data: { session: currentSession } } = await supabase.auth.getSession()
      session.value = currentSession
      user.value = currentSession?.user ?? null

      // 监听认证状态变化
      supabase.auth.onAuthStateChange((_event, newSession) => {
        session.value = newSession
        user.value = newSession?.user ?? null
      })
    } catch (error) {
      console.error('Initialize auth error:', error)
    } finally {
      loading.value = false
    }
  }

  // 注册
  async function signUp(email, password) {
    loading.value = true
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
      })
      if (error) throw error
      return { data, error: null }
    } catch (error) {
      console.error('Sign up error:', error)
      return { data: null, error }
    } finally {
      loading.value = false
    }
  }

  // 登录
  async function signIn(email, password) {
    loading.value = true
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })
      if (error) throw error
      return { data, error: null }
    } catch (error) {
      console.error('Sign in error:', error)
      return { data: null, error }
    } finally {
      loading.value = false
    }
  }

  // 登出
  async function signOut() {
    loading.value = true
    try {
      const { error } = await supabase.auth.signOut()
      if (error) throw error
      user.value = null
      session.value = null
    } catch (error) {
      console.error('Sign out error:', error)
    } finally {
      loading.value = false
    }
  }

  return {
    user,
    session,
    loading,
    isAuthenticated,
    initialize,
    signUp,
    signIn,
    signOut,
  }
})
