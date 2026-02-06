<template>
  <div class="card">
    <h2 class="text-2xl font-bold text-gray-800 mb-2 text-center">
      🧧 提交你的分数
    </h2>
    <p class="text-sm text-gray-600 text-center mb-6">
      三人分数之和等于2026，即可互享口令红包！
    </p>
    
    <form @submit.prevent="handleSubmit" class="space-y-4">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">
          芝麻分 <span class="text-red-500">*</span>
        </label>
        <input
          v-model.number="score"
          type="number"
          required
          min="0"
          max="950"
          class="input"
          placeholder="输入你的芝麻分 (0-950)"
        />
      </div>
      
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">
          口令 <span class="text-red-500">*</span>
        </label>
        <input
          v-model="command"
          type="text"
          required
          class="input"
          placeholder="输入口令"
        />
      </div>
      
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">
          邮箱 <span class="text-red-500">*</span>
        </label>
        <input
          v-model="email"
          type="email"
          required
          class="input"
          placeholder="接收匹配通知的邮箱"
        />
      </div>
      
      <div v-if="error" class="text-red-500 text-sm bg-red-50 p-3 rounded-lg">
        {{ error }}
      </div>
      
      <div v-if="success" class="text-green-600 text-sm bg-green-50 p-3 rounded-lg">
        {{ success }}
      </div>
      
      <button
        type="submit"
        :disabled="loading"
        class="btn btn-primary w-full text-lg"
      >
        {{ loading ? '提交中...' : '🚀 提交分数' }}
      </button>
    </form>

    <button
      v-if="canRematch"
      @click="handleRematch"
      :disabled="rematchLoading"
      class="btn btn-secondary w-full mt-4"
    >
      {{ rematchLoading ? '匹配中...' : '🔄 再次匹配' }}
    </button>
    
    <div class="mt-6 space-y-2 text-xs text-gray-500">
      <p>📢 同一邮箱每日最多提交 2 次</p>
      <p>📢 提交后自动匹配一次，点击"再次匹配"寻找新队伍</p>
      <p>📢 优先匹配800+分，每次返回不同队伍</p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { supabase, TABLES } from '@/lib/supabase'
import { translateError } from '@/lib/error'

const authStore = useAuthStore()

const score = ref(null)
const command = ref('')
const email = ref(authStore.user?.email || '')
const loading = ref(false)
const rematchLoading = ref(false)
const error = ref('')
const success = ref('')
const canRematch = ref(false)

const handleSubmit = async () => {
  error.value = ''
  success.value = ''
  
  if (!authStore.isAuthenticated) {
    error.value = '请先登录后再提交分数'
    return
  }
  
  if (score.value < 0 || score.value > 950) {
    error.value = '分数必须在 0-950 之间'
    return
  }

  if (!email.value) {
    error.value = '请填写邮箱'
    return
  }
  
  loading.value = true
  
  try {
    const startOfDay = new Date()
    startOfDay.setHours(0, 0, 0, 0)

    const { count: todayCount, error: countError } = await supabase
      .from(TABLES.SCORES)
      .select('id', { count: 'exact', head: true })
      .eq('email', email.value)
      .gte('created_at', startOfDay.toISOString())

    if (countError) throw countError

    if ((todayCount || 0) >= 2) {
      error.value = '同一邮箱每天最多提交 2 次，请明天再来'
      return
    }

    const { data, error: insertError } = await supabase
      .from(TABLES.SCORES)
      .insert([
        {
          user_id: authStore.user.id,
          score: score.value,
          command: command.value,
          email: email.value,
          status: 'pending'
        }
      ])
      .select()
    
    if (insertError) throw insertError
    
    success.value = '✅ 提交成功！系统将自动为您匹配。'
    canRematch.value = true
    
    // 清空表单
    score.value = null
    command.value = ''
    
    // 触发首次匹配
    await triggerMatching()
    
  } catch (err) {
    console.error('Submit error:', err)
    error.value = translateError(err)
  } finally {
    loading.value = false
  }
}

// 触发匹配算法（调用数据库函数）
const triggerMatching = async () => {
  try {
    const { data, error } = await supabase.rpc('find_single_match', {
      p_user_id: authStore.user.id
    })
    if (error) console.error('Matching error:', error)
    else console.log('Matching completed:', data)
  } catch (err) {
    console.error('Trigger matching error:', err)
  }
}

// 再次匹配
const handleRematch = async () => {
  error.value = ''
  success.value = ''
  rematchLoading.value = true
  
  try {
    const { data, error: matchError } = await supabase.rpc('find_single_match', {
      p_user_id: authStore.user.id
    })
    
    if (matchError) throw matchError
    
    if (data && data.length > 0) {
      success.value = '✅ 找到新的匹配队伍！请查看匹配记录。'
    } else {
      error.value = '暂未找到新的匹配队伍，请稍后再试'
    }
  } catch (err) {
    console.error('Rematch error:', err)
    error.value = translateError(err)
  } finally {
    rematchLoading.value = false
  }
}
</script>
