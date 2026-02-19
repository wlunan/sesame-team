import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import Home from '@/views/Home.vue'
import ActivityEnded from '@/views/ActivityEnded.vue'
import MyMatches from '@/views/MyMatches.vue'

const routes = [
  {
    path: '/',
    name: 'ActivityEnded',
    component: ActivityEnded,
  },
  {
    path: '/home',
    name: 'Home',
    component: Home,
  },
  {
    path: '/my-matches',
    name: 'MyMatches',
    component: MyMatches,
    meta: { requiresAuth: true }
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// 路由守卫
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/')
  } else {
    next()
  }
})

export default router
