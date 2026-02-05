<template>
  <div class="min-h-screen py-8 px-4">
    <div class="max-w-4xl mx-auto">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold text-gray-800">
          我的匹配记录
        </h1>
        <router-link to="/" class="btn btn-secondary">
          返回首页
        </router-link>
      </div>
      
      <MatchList />
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import MatchList from '@/components/MatchList.vue'

const authStore = useAuthStore()
const router = useRouter()

onMounted(async () => {
  await authStore.initialize()
  if (!authStore.isAuthenticated) {
    router.push('/')
  }
})
</script>
