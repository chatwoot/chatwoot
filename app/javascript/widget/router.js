import { createRouter, createWebHashHistory } from 'vue-router';
import ViewWithHeader from './components/layouts/ViewWithHeader.vue';
import UnreadMessages from './views/UnreadMessages.vue';
import Campaigns from './views/Campaigns.vue';
import Home from './views/Home.vue';
import PreChatForm from './views/PreChatForm.vue';
import Messages from './views/Messages.vue';
import ArticleViewer from './views/ArticleViewer.vue';

export default createRouter({
  history: createWebHashHistory(),
  routes: [
    {
      path: '/unread-messages',
      name: 'unread-messages',
      component: UnreadMessages,
    },
    {
      path: '/campaigns',
      name: 'campaigns',
      component: Campaigns,
    },
    {
      path: '/',
      component: ViewWithHeader,
      children: [
        {
          path: '',
          name: 'home',
          component: Home,
        },
        {
          path: '/prechat-form',
          name: 'prechat-form',
          component: PreChatForm,
        },
        {
          path: '/messages',
          name: 'messages',
          component: Messages,
        },
        {
          path: '/article',
          name: 'article-viewer',
          component: ArticleViewer,
        },
      ],
    },
  ],
});
