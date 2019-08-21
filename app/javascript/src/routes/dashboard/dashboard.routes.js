import AppContainer from './Dashboard';
import settings from './settings/settings.routes';
import conversation from './conversation/conversation.routes';

export default {
  routes: [
    {
      path: '/u/',
      component: AppContainer,
      children: [...conversation.routes, ...settings.routes],
    },
  ],
};
