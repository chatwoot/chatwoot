import { createRouter, createWebHashHistory } from 'vue-router';
import HomeView from 'widget-v2/views/HomeView.vue';
import ConversationsView from 'widget-v2/views/ConversationsView.vue';
import ConversationView from 'widget-v2/views/ConversationView.vue';
import ComposeView from 'widget-v2/views/ComposeView.vue';
import AiView from 'widget-v2/views/AiView.vue';
import ArticlesView from 'widget-v2/views/ArticlesView.vue';
import ArticleView from 'widget-v2/views/ArticleView.vue';

export default createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', name: 'home', component: HomeView, meta: { tabBar: true } },
    {
      path: '/conversations',
      name: 'conversations',
      component: ConversationsView,
      meta: { tabBar: true },
    },
    {
      path: '/conversations/new',
      name: 'compose',
      component: ComposeView,
      meta: { section: 'human' },
    },
    {
      path: '/conversations/:id',
      name: 'conversation-detail',
      component: ConversationView,
    },
    { path: '/ai', name: 'ai', component: AiView, meta: { tabBar: true } },
    {
      path: '/ai/new',
      name: 'ai-compose',
      component: ComposeView,
      meta: { section: 'ai' },
    },
    {
      path: '/help',
      name: 'help',
      component: ArticlesView,
      meta: { tabBar: true },
    },
    { path: '/help/:slug', name: 'help-article', component: ArticleView },
  ],
});
