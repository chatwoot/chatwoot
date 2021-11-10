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
      // route level code-splitting
      // this generates a separate chunk (about.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: Unread,
    },
    {
      path: '/campaign',
      name: 'campaign',
      // route level code-splitting
      // this generates a separate chunk (about.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: Campaign,
    },
    {
      path: '/conversations',
      name: 'conversations',
      // route level code-splitting
      // this generates a separate chunk (about.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: Conversations,
    },
    {
      path: '/conversations/prechat',
      name: 'prechat',
      // route level code-splitting
      // this generates a separate chunk (about.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: PreChat,
    },
    {
      path: '/conversations/:conversationId',
      name: 'chat',
      // route level code-splitting
      // this generates a separate chunk (about.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: Chat,
    },
  ],
});
