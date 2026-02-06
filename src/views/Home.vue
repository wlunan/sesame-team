<template>
  <div class="min-h-screen py-8 px-4">
    <div class="max-w-6xl mx-auto">
      <!-- 头部 -->
      <header class="text-center mb-8">
        <h1 class="text-4xl md:text-5xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-red-600 to-orange-600 mb-2">
          🧧 合成2026分数
        </h1>
        <p class="text-lg text-gray-600">
          三人分数之和等于2026，即可组队获取口令红包！
        </p>
      </header>

      <!-- 登录状态提示 -->
      <div v-if="!authStore.isAuthenticated" class="mb-8">
        <div class="card max-w-2xl mx-auto bg-yellow-50 border-2 border-yellow-200">
          <div class="text-center">
            <p class="text-yellow-800 font-medium mb-4">
              ⚠️ 为防止恶意填写，登录后即可提交分数参与匹配
            </p>
            <AuthForm />
          </div>
        </div>
      </div>

      <!-- 已登录用户内容 -->
      <div v-else>
        <div class="mb-8">
          <StatsSummary />
        </div>
        <div class="grid md:grid-cols-2 gap-6 mb-8">
          <!-- 提交分数 -->
          <ScoreSubmit />
          
          <!-- 搜索分数 -->
          <SearchScore />
        </div>

        <div class="grid md:grid-cols-2 gap-6 mb-8">
          <!-- 最新记录（全站） -->
          <RecentScores />

          <!-- 我的提交记录 -->
          <MySubmissions />
        </div>

        <!-- 我的匹配记录 -->
        <MatchList />
      </div>

      <!-- 帮助信息 -->
      <div class="mt-8 card max-w-2xl mx-auto bg-blue-50 border border-blue-200">
        <h3 class="font-bold text-blue-900 mb-2">📢 使用说明</h3>
        <ul class="text-sm text-blue-800 space-y-1">
          <li>• 测试反馈群：1051552472，若出现问题请加群反馈</li>
          <li>• 可提交口令后，直接搜索需要的分数</li>
          <!-- <li>• 匹配成功邮件将会发送到您填写的邮箱</li> -->
          <li>• 匹配逻辑已更新，一个分数可用于多人匹配</li>
          <li>• 优先匹配800+分，支持多组匹配</li>
          <li>• 已增加口令失效举报功能</li>
        </ul>
      </div>

      <!-- 页脚 -->
      <footer class="text-center mt-8 text-sm text-gray-500">
        <p>本项目仅供测试学习使用</p>
      </footer>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import AuthForm from '@/components/AuthForm.vue'
import ScoreSubmit from '@/components/ScoreSubmit.vue'
import SearchScore from '@/components/SearchScore.vue'
import MatchList from '@/components/MatchList.vue'
import RecentScores from '@/components/RecentScores.vue'
import MySubmissions from '@/components/MySubmissions.vue'
import StatsSummary from '@/components/StatsSummary.vue'

const authStore = useAuthStore()

onMounted(async () => {
  await authStore.initialize()
})
</script>
