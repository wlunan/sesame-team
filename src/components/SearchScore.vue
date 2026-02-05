<template>
  <div class="card">
    <h3 class="text-xl font-bold text-gray-800 mb-4">
      🔍 搜索分数
    </h3>
    
    <div class="flex gap-2 mb-4">
      <input
        v-model.number="searchScore"
        type="number"
        min="0"
        max="950"
        class="input flex-1"
        placeholder="输入你需要的分数"
        @keyup.enter="handleSearch"
      />
      <button
        @click="handleSearch"
        :disabled="loading"
        class="btn btn-primary"
      >
        {{ loading ? '搜索中...' : '搜索' }}
      </button>
    </div>
    
    <div v-if="error" class="text-red-500 text-sm mb-4">
      {{ error }}
    </div>
    
    <div v-if="results.length > 0" class="space-y-2">
      <p class="text-sm text-gray-600 mb-2">
        找到 {{ results.length }} 个匹配结果：
      </p>
      <div
        v-for="result in results"
        :key="result.id"
        class="bg-gray-50 p-3 rounded-lg text-sm"
      >
        <div class="flex justify-between items-center">
          <div>
            <span class="font-bold text-red-600">{{ result.score }}</span> 分
            <span class="text-gray-500 ml-2">
              提交于 {{ formatDate(result.created_at) }}
            </span>
          </div>
          <span
            :class="{
              'text-green-600': result.status === 'pending',
              'text-gray-400': result.status === 'matched'
            }"
            class="text-xs font-medium"
          >
            {{ result.status === 'pending' ? '可用' : '已匹配' }}
          </span>
        </div>
      </div>
    </div>
    
    <div v-else-if="searched" class="text-center text-gray-500 py-4">
      暂无该分数的记录
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { supabase, TABLES } from '@/lib/supabase'
import { translateError } from '@/lib/error'

const authStore = useAuthStore()

const searchScore = ref(null)
const results = ref([])
const loading = ref(false)
const error = ref('')
const searched = ref(false)

const handleSearch = async () => {
  if (!authStore.isAuthenticated) {
    error.value = '请先登录后再搜索'
    return
  }

  if (!searchScore.value && searchScore.value !== 0) {
    error.value = '请输入要搜索的分数'
    return
  }
  
  error.value = ''
  loading.value = true
  searched.value = true
  
  try {
    const startOfDay = new Date()
    startOfDay.setHours(0, 0, 0, 0)

    const { count: todayCount, error: countError } = await supabase
      .from('search_logs')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', authStore.user.id)
      .gte('created_at', startOfDay.toISOString())

    if (countError) throw countError

    if ((todayCount || 0) >= 5) {
      error.value = '每天最多搜索 5 次，请明天再试'
      return
    }

    const { data, error: searchError } = await supabase
      .from(TABLES.SCORES)
      .select('*')
      .eq('score', searchScore.value)
      .order('created_at', { ascending: false })
      .limit(10)
    
    if (searchError) throw searchError
    
    results.value = data || []

    const { error: logError } = await supabase
      .from('search_logs')
      .insert([
        {
          user_id: authStore.user.id,
          score: searchScore.value
        }
      ])

    if (logError) throw logError
    
  } catch (err) {
    console.error('Search error:', err)
    error.value = translateError(err)
  } finally {
    loading.value = false
  }
}

const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleString('zh-CN', {
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}
</script>
