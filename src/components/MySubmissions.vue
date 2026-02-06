<template>
  <div class="card">
    <div class="flex justify-between items-center mb-4">
      <h3 class="text-xl font-bold text-gray-800">
        🗂 我的提交记录
      </h3>
      <button
        @click="loadMySubmissions"
        :disabled="loading"
        class="btn btn-secondary text-sm"
      >
        {{ loading ? '刷新中...' : '🔄 刷新' }}
      </button>
    </div>

    <div v-if="error" class="text-red-500 text-sm mb-4 bg-red-50 p-3 rounded-lg">
      {{ error }}
    </div>

    <div v-if="loading && records.length === 0" class="text-center py-6 text-gray-500">
      加载中...
    </div>

    <div v-else-if="records.length === 0" class="text-center py-6 text-gray-500">
      暂无提交记录
    </div>

    <div v-else class="space-y-3">
      <div
        v-for="record in records"
        :key="record.id"
        class="bg-gray-50 p-3 rounded-lg text-sm"
      >
        <div class="flex justify-between items-center mb-2">
          <div>
            <span class="font-bold text-red-600">{{ record.score }}</span> 分
            <span class="text-gray-500 ml-2">
              {{ formatDate(record.created_at) }}
            </span>
          </div>
          <span
            :class="{
              'text-green-600': record.status === 'pending',
              'text-gray-400': record.status === 'matched',
              'text-red-500': record.status === 'invalid'
            }"
            class="text-xs font-medium"
          >
            {{ getStatusText(record.status) }}
          </span>
        </div>
        <div class="flex items-center justify-between text-xs text-gray-600">
          <div>
            口令：<span class="font-mono bg-white px-2 py-1 rounded">{{ record.command }}</span>
          </div>
          <button
            @click="copyToClipboard(record.command)"
            class="text-blue-600 hover:text-blue-800 underline ml-2"
          >
            📋 复制
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { supabase, TABLES } from '@/lib/supabase'
import { translateError } from '@/lib/error'

const authStore = useAuthStore()

const records = ref([])
const loading = ref(false)
const error = ref('')

onMounted(() => {
  loadMySubmissions()
})

const loadMySubmissions = async () => {
  if (!authStore.isAuthenticated) {
    error.value = '请先登录'
    return
  }

  loading.value = true
  error.value = ''

  try {
    const { data, error: queryError } = await supabase
      .from(TABLES.SCORES)
      .select('id, score, command, status, created_at')
      .eq('user_id', authStore.user.id)
      .order('created_at', { ascending: false })
      .limit(6)

    if (queryError) throw queryError

    records.value = data || []
  } catch (err) {
    console.error('Load my submissions error:', err)
    error.value = translateError(err)
  } finally {
    loading.value = false
  }
}

const getStatusText = (status) => {
  const statusMap = {
    pending: '待匹配',
    matched: '已匹配',
    invalid: '已失效'
  }
  return statusMap[status] || status
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

const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text)
    alert('口令已复制到剪贴板！')
  } catch (err) {
    console.error('复制失败:', err)
    alert('复制失败，请手动复制')
  }
}
</script>
