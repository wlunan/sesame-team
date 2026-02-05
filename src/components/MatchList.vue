<template>
  <div class="card">
    <div class="flex justify-between items-center mb-4">
      <h3 class="text-xl font-bold text-gray-800">
        🎉 我的匹配记录
      </h3>
      <button
        @click="loadMatches"
        :disabled="loading"
        class="btn btn-secondary text-sm"
      >
        {{ loading ? '刷新中...' : '🔄 刷新' }}
      </button>
    </div>
    
    <div v-if="error" class="text-red-500 text-sm mb-4 bg-red-50 p-3 rounded-lg">
      {{ error }}
    </div>
    
    <div v-if="loading && matches.length === 0" class="text-center py-8 text-gray-500">
      加载中...
    </div>
    
    <div v-else-if="matches.length === 0" class="text-center py-8 text-gray-500">
      暂无匹配记录
    </div>
    
    <div v-else class="space-y-4">
      <div
        v-for="match in matches"
        :key="match.match_id"
        class="bg-gradient-to-r from-red-50 to-orange-50 p-4 rounded-xl border border-red-100"
      >
        <div class="flex justify-between items-start mb-3">
          <div>
            <span class="text-xs text-gray-500">
              匹配时间: {{ formatDate(match.matched_at) }}
            </span>
          </div>
          <span
            :class="{
              'bg-green-100 text-green-700': match.status === 'active',
              'bg-gray-100 text-gray-600': match.status === 'expired',
              'bg-red-100 text-red-700': match.status === 'reported'
            }"
            class="text-xs px-2 py-1 rounded-full font-medium"
          >
            {{ getStatusText(match.status) }}
          </span>
        </div>
        
        <div class="grid grid-cols-3 gap-3 mb-3">
          <div
            v-for="(item, index) in getMatchItems(match)"
            :key="index"
            :class="{
              'bg-yellow-100 border-yellow-300': item.isMine
            }"
            class="bg-white p-3 rounded-lg border border-gray-200 text-center"
          >
            <div class="text-2xl font-bold text-red-600 mb-1">
              {{ item.score }}
            </div>
            <div class="text-xs text-gray-600 mb-2">
              {{ item.isMine ? '(我的)' : '' }}
            </div>
            <div class="text-xs font-mono bg-gray-100 px-2 py-1 rounded break-all">
              {{ item.command }}
            </div>
          </div>
        </div>
        
        <div class="flex justify-between items-center pt-3 border-t border-red-200">
          <div class="text-sm">
            总和: <span class="font-bold text-red-600 text-lg">2026</span>
          </div>
          <button
            v-if="match.status === 'active'"
            @click="reportMatch(match.match_id)"
            class="text-xs text-gray-500 hover:text-red-600 underline"
          >
            举报失效
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import { translateError } from '@/lib/error'

const authStore = useAuthStore()

const matches = ref([])
const loading = ref(false)
const error = ref('')

onMounted(() => {
  loadMatches()
})

const loadMatches = async () => {
  if (!authStore.isAuthenticated) {
    error.value = '请先登录'
    return
  }
  
  loading.value = true
  error.value = ''
  
  try {
    // 使用视图查询匹配详情
    const { data, error: queryError } = await supabase
      .from('user_match_details')
      .select('*')
      .or(`user_id_1.eq.${authStore.user.id},user_id_2.eq.${authStore.user.id},user_id_3.eq.${authStore.user.id}`)
      .order('matched_at', { ascending: false })
    
    if (queryError) throw queryError
    
    matches.value = data || []
    
  } catch (err) {
    console.error('Load matches error:', err)
    error.value = translateError(err)
  } finally {
    loading.value = false
  }
}

const getMatchItems = (match) => {
  const userId = authStore.user?.id
  return [
    {
      score: match.score_1,
      command: match.command_1,
      isMine: match.user_id_1 === userId
    },
    {
      score: match.score_2,
      command: match.command_2,
      isMine: match.user_id_2 === userId
    },
    {
      score: match.score_3,
      command: match.command_3,
      isMine: match.user_id_3 === userId
    }
  ]
}

const getStatusText = (status) => {
  const statusMap = {
    active: '有效',
    expired: '已过期',
    reported: '已举报'
  }
  return statusMap[status] || status
}

const reportMatch = async (matchId) => {
  if (!confirm('确定要举报此匹配为失效吗？')) return
  
  try {
    const { error: reportError } = await supabase
      .from('reports')
      .insert([
        {
          match_id: matchId,
          reporter_id: authStore.user.id,
          reason: '口令失效'
        }
      ])
    
    if (reportError) throw reportError
    
    // 更新匹配状态
    await supabase
      .from('matches')
      .update({ status: 'reported' })
      .eq('id', matchId)
    
    alert('举报成功！')
    loadMatches()
    
  } catch (err) {
    console.error('Report error:', err)
    alert(translateError(err))
  }
}

const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}
</script>
