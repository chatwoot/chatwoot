import { frontendURL } from '../../../../helper/URLHelper';
import Index from './Index.vue';
import EditPrompt from './EditPrompt.vue';
import SettingsWrapper from '../SettingsWrapper.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/prompts'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'prompts_list',
          component: Index,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: ':id/edit',
          name: 'prompts_edit',
          component: EditPrompt,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
