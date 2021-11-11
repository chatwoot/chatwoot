import Vue from 'vue';
import Router from 'vue-router';
import Home from './views/Home.vue';
import Unread from './views/Unread';
import Campaign from './views/Campaign';
import Conversations from './views/Conversations';
import Chat from './views/Chat';
import PreChat from './views/PreChat';

Vue.use(Router);

export default new Router({
  mode: 'hash',
  routes: [
    {
      path: '/',
      name: 'home',
      component: Home,
    },
    {
      path: '/unread',
      name: 'unread',
      component: Unread,
    },
    {
      path: '/campaign',
      name: 'campaign',
      component: Campaign,
    },
    {
      path: '/conversations',
      name: 'conversations',
      component: Conversations,
    },
    {
      path: '/conversations/prechat',
      name: 'prechat',
      component: PreChat,
    },
    {
      path: '/conversations/:conversationId',
      name: 'chat',
      component: Chat,
    },
  ],
});
