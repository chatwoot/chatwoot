import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const Index = () => import('./Index.vue');
const ChatbotEdit = () => import('./Edit/Index.vue');
const CreateIndex = () => import('./Create/Index.vue');
const ConnectInbox = () => import('./Create/ConnectInbox.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/chatbot'),
      roles: ['administrator'],
      component: SettingsContent,
      props: {
        headerTitle: 'CHATBOT.TITLE',
        icon: 'chatbot-icon',
        showNewButton: true,
      },
      children: [
        {
          path: '',
          name: 'chatbot_index',
          component: Index,
          roles: ['administrator'],
        },
        {
          path: 'create', // This is the path for creating a new chatbot
          name: 'chatbot_new',
          component: CreateIndex, // Use the component for creating a new chatbot
          roles: ['administrator'],
        },
        {
          path: 'create/connect_inbox',
          name: 'chatbot_connect_inbox',
          component: ConnectInbox,
          roles: ['administrator'],
        },
        {
          path: 'edit/:chatbotId',
          name: 'chatbot_edit',
          component: ChatbotEdit,
          roles: ['administrator'],
          props: true, // Pass route parameters as props
        },
      ],
    },
  ],
};
