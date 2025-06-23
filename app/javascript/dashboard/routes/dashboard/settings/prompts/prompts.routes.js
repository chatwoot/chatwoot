import { frontendURL } from '../../../../helper/URLHelper';
import { FEATURE_FLAGS } from '../../../../featureFlags';
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
            featureFlag: FEATURE_FLAGS.PROMPTS,
            permissions: ['administrator'],
          },
        },
        {
          path: ':id/edit',
          name: 'prompts_edit',
          component: EditPrompt,
          meta: {
            featureFlag: FEATURE_FLAGS.PROMPTS,
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
