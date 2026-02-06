<template>
  <div class="min-h-screen">
    <!-- 导航栏 -->
    <nav v-if="authStore.isAuthenticated" class="bg-white shadow-sm border-b">
      <div class="max-w-6xl mx-auto px-4 py-3">
        <div class="flex justify-between items-center">
          <router-link to="/" class="text-xl font-bold text-red-600">
            🧧 合成2026
          </router-link>
          <div class="flex items-center gap-4">
            <span class="text-sm text-gray-600">
              {{ authStore.user?.email }}
            </span>
            <router-link
              to="/my-matches"
              class="text-sm text-gray-700 hover:text-red-600"
            >
              我的匹配
            </router-link>
            <button
              @click="handleLogout"
              class="text-sm text-gray-700 hover:text-red-600"
            >
              退出登录
            </button>
          </div>
        </div>
      </div>
    </nav>

    <!-- 主要内容 -->
    <router-view />

    <footer class="border-t bg-white">
      <div class="max-w-6xl mx-auto px-4 py-4 text-center">
        <a
          href="https://link3.cc/lunan"
          target="_blank"
          rel="noopener noreferrer"
          class="text-base font-semibold text-red-600 hover:text-red-700"
        >
          更多内容
        </a>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

onMounted(async () => {
  await authStore.initialize()
})

const handleLogout = async () => {
  if (confirm('确定要退出登录吗？')) {
    await authStore.signOut()
  }
}
</script>
