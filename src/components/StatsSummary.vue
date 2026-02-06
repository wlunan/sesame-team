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
import { supabase, TABLES } from '@/lib/supabase'
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
    const { count: pendingCount, error: pendingError } = await supabase
      .from(TABLES.SCORES)
      .select('id', { count: 'exact', head: true })
      .eq('status', 'pending')

    if (pendingError) throw pendingError

    pendingPeople.value = pendingCount || 0

    const { data: matchRows, error: matchError } = await supabase
      .from(TABLES.MATCHES)
      .select('score_id_1, score_id_2, score_id_3')
      .eq('status', 'active')

    if (matchError) throw matchError

    const uniqueIds = new Set()
    for (const row of matchRows || []) {
      if (row.score_id_1) uniqueIds.add(row.score_id_1)
      if (row.score_id_2) uniqueIds.add(row.score_id_2)
      if (row.score_id_3) uniqueIds.add(row.score_id_3)
    }

    matchedPeople.value = uniqueIds.size

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
