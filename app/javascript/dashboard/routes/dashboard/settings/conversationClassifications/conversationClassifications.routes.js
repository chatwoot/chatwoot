import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL(
        'accounts/:accountId/settings/conversation-classifications'
      ),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'conversation_classifications_wrapper',
          meta: {
            permissions: ['administrator'],
          },
          redirect: to => {
            return {
              name: 'conversation_classifications_list',
              params: to.params,
            };
          },
        },
        {
          path: 'list',
          name: 'conversation_classifications_list',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};
