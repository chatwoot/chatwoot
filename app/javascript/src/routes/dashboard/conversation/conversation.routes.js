/* eslint arrow-body-style: 0 */
import ConversationView from './ConversationView';

export default {
  routes: [
    {
      path: '/u/dashboard',
      name: 'home',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: () => {
        return { inboxId: 0 };
      },
    },
    {
      path: '/u/inbox/:inbox_id',
      name: 'inbox_dashboard',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: (route) => {
        return { inboxId: route.params.inbox_id };
      },
    },
    {
      path: '/u/conversations/:conversation_id',
      name: 'inbox_conversation',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: (route) => {
        return { conversationId: route.params.conversation_id };
      },
    },
  ],
};
