import AppContainer from './Dashboard';
import settings from './settings/settings.routes';
import conversation from './conversation/conversation.routes';
import { frontendURL } from '../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL(''),
      component: AppContainer,
      children: [...conversation.routes, ...settings.routes],
    },
  ],
};
