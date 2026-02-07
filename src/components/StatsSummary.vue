<template>
  <div class="card p-4">
    <div class="flex justify-between items-center mb-3">
      <h3 class="text-lg font-bold text-gray-800">📊 平台统计</h3>
      <button
        @click="loadStats"
        :disabled="loading"
        class="btn btn-secondary text-xs"
      >
        {{ loading ? '刷新中...' : '🔄 刷新' }}
      </button>
    </div>

    <div v-if="error" class="text-red-500 text-sm mb-4 bg-red-50 p-3 rounded-lg">
      {{ error }}
    </div>

    <div class="grid grid-cols-2 gap-3">
      <div class="bg-red-50 rounded-lg p-3 text-center">
        <div class="text-xs text-gray-600 mb-1">匹配成功人数</div>
        <div class="text-2xl font-bold text-red-600">{{ matchedPeople }}</div>
      </div>
      <div class="bg-orange-50 rounded-lg p-3 text-center">
        <div class="text-xs text-gray-600 mb-1">当前匹配人数</div>
        <div class="text-2xl font-bold text-orange-600">{{ pendingPeople }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { translateError } from '@/lib/error'

const matchedPeople = ref(0)
const pendingPeople = ref(0)
const loading = ref(false)
const error = ref('')

const CACHE_KEY = 'stats_summary_cache'
const CACHE_TTL_MS = 60 * 1000

onMounted(() => {
  loadStats()
})

const loadStats = async () => {
  const cached = getCachedStats()
  if (cached) {
    matchedPeople.value = cached.matchedPeople
    pendingPeople.value = cached.pendingPeople
  }

  loading.value = true
  error.value = ''

  try {
    const { data, error: statsError } = await supabase.rpc('get_platform_stats')

    if (statsError) throw statsError

    const stats = Array.isArray(data) ? data[0] : data
    pendingPeople.value = stats?.pending_people || 0
    matchedPeople.value = stats?.matched_people || 0

    setCachedStats({
      matchedPeople: matchedPeople.value,
      pendingPeople: pendingPeople.value
    })
  } catch (err) {
    console.error('Load stats error:', err)
    error.value = translateError(err)
  } finally {
    loading.value = false
  }
}

const getCachedStats = () => {
  try {
    const raw = localStorage.getItem(CACHE_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw)
    if (!parsed || !parsed.timestamp) return null
    if (Date.now() - parsed.timestamp > CACHE_TTL_MS) return null
    return parsed.data || null
  } catch {
    return null
  }
}

const setCachedStats = (data) => {
  try {
    localStorage.setItem(
      CACHE_KEY,
      JSON.stringify({
        timestamp: Date.now(),
        data
      })
    )
  } catch {
    // 忽略缓存写入失败
  }
}
</script>
