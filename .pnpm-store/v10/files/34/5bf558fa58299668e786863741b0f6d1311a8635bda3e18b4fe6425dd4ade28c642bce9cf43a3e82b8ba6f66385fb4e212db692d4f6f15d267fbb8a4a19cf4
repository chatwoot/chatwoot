import { createRouter, createWebHashHistory, createWebHistory } from 'vue-router'
import { histoireConfig } from './util/config'

export const base = import.meta.env.BASE_URL as string

function createRouterHistory() {
  switch (histoireConfig.routerMode) {
    case 'hash': return createWebHashHistory(base)
    case 'history':
    default:
      return createWebHistory(base)
  }
}

export const router = createRouter({
  history: createRouterHistory(),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('./components/HomeView.vue'),
    },
    {
      path: '/story/:storyId',
      name: 'story',
      component: () => import('./components/story/StoryView.vue'),
    },
  ],
})
