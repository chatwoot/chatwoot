import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import ConversationWorkflowIndex from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/conversation-workflow'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'conversation_workflow_index', params: to.params };
          },
        },
        {
          path: 'index',
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
