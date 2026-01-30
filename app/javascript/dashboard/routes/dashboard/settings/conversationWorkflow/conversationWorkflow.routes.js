import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import ConversationWorkflowIndex from './index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/conversation-workflow'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'conversation_workflow_index',
          component: ConversationWorkflowIndex,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
