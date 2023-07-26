import Vue from 'vue';
import Router from 'vue-router';
import ViewWithHeader from './components/layouts/ViewWithHeader.vue';

Vue.use(Router);

export default new Router({
  mode: 'hash',
  routes: [
    {
      path: '/unread-messages',
      name: 'unread-messages',
      component: () => import('./views/UnreadMessages.vue'),
    },
    {
      path: '/campaigns',
      name: 'campaigns',
      component: () => import('./views/Campaigns.vue'),
    },
    {
      path: '/',
      component: ViewWithHeader,
      children: [
        {
          path: '',
          name: 'home',
          component: () => import('./views/Home.vue'),
        },
        {
          path: '/prechat-form',
          name: 'prechat-form',
          component: () => import('./views/PreChatForm.vue'),
        },
        {
          path: '/messages',
          name: 'messages',
          component: () => import('./views/Messages.vue'),
        },
        {
          path: '/article',
          name: 'article-viewer',
          props: true,
          component: () => import('./views/ArticleViewer.vue'),
        },
      ],
    },
  ],
});
