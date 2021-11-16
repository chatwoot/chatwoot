import Vue from 'vue';
import Router from 'vue-router';
import Home from './views/Home.vue';
import Unread from './views/Unread';
import ViewWithHeader from './components/layouts/ViewWithHeader.vue';
import PreChatForm from './views/PreChatForm.vue';
import Messages from './views/Messages.vue';

Vue.use(Router);

export default new Router({
  mode: 'hash',
  routes: [
    {
      path: '/unread-messages',
      name: 'unread-messages',
      component: Unread,
    },
    {
      path: '/campaigns',
      name: 'campaigns',
      component: Unread,
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
      ],
    },
  ],
});
