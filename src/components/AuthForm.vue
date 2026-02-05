<template>
  <div class="max-w-md mx-auto">
    <div class="card">
      <h2 class="text-2xl font-bold text-gray-800 mb-6 text-center">
        {{ isLogin ? '登录' : '注册' }}
      </h2>
      
      <form @submit.prevent="handleSubmit" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            邮箱
          </label>
          <input
            v-model="email"
            type="email"
            required
            class="input"
            placeholder="your@email.com"
          />
        </div>
        
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            密码
          </label>
          <input
            v-model="password"
            type="password"
            required
            minlength="6"
            class="input"
            placeholder="至少6位"
          />
        </div>
        
        <div v-if="error" class="text-red-500 text-sm">
          {{ error }}
        </div>
        
        <div v-if="success" class="text-green-500 text-sm">
          {{ success }}
        </div>
        
        <button
          type="submit"
          :disabled="loading"
          class="btn btn-primary w-full"
        >
          {{ loading ? '处理中...' : (isLogin ? '登录' : '注册') }}
        </button>
      </form>
      
      <div class="mt-4 text-center text-sm text-gray-600">
        {{ isLogin ? '还没有账号？' : '已有账号？' }}
        <button
          @click="toggleMode"
          class="text-red-500 hover:text-red-600 font-medium"
        >
          {{ isLogin ? '立即注册' : '立即登录' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { translateError } from '@/lib/error'

const authStore = useAuthStore()

const isLogin = ref(true)
const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')
const success = ref('')

const toggleMode = () => {
  isLogin.value = !isLogin.value
  error.value = ''
  success.value = ''
}

const handleSubmit = async () => {
  error.value = ''
  success.value = ''
  loading.value = true
  
  try {
    if (isLogin.value) {
      const { error: signInError } = await authStore.signIn(email.value, password.value)
      if (signInError) {
        error.value = translateError(signInError)
      } else {
        success.value = '登录成功！'
        email.value = ''
        password.value = ''
      }
    } else {
      const { error: signUpError } = await authStore.signUp(email.value, password.value)
      if (signUpError) {
        error.value = translateError(signUpError)
      } else {
        success.value = '注册成功！请检查邮箱确认注册。'
        email.value = ''
        password.value = ''
      }
    }
  } finally {
    loading.value = false
  }
}
</script>
