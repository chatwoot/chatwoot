/* eslint arrow-body-style: 0 */
import ConversationView from './ConversationView';
import { frontendURL } from '../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('dashboard'),
      name: 'home',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: () => {
        return { inboxId: 0 };
      },
    },
    {
      path: frontendURL('inbox/:inbox_id'),
      name: 'inbox_dashboard',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => {
        return { inboxId: route.params.inbox_id };
      },
    },
    {
      path: frontendURL('conversations/:conversation_id'),
      name: 'inbox_conversation',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => {
        return { inboxId: 0, conversationId: route.params.conversation_id };
      },
    },
    {
      path: frontendURL('inbox/:inbox_id/conversations/:conversation_id'),
      name: 'conversation_through_inbox',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => {
        return {
          conversationId: route.params.conversation_id,
          inboxId: route.params.inbox_id,
        };
      },
    },
  ],
};
