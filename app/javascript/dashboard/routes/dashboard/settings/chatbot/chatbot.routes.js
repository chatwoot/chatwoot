import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const Index = () => import('./Index.vue');
const ChatbotEdit = () => import('./Edit/Index.vue');
const CreateStepWrap = () => import('./Create/Index.vue');
const UploadFiles = () => import('./Create/FileUploader.vue');
const ConnectInbox = () => import('./Create/ConnectInbox.vue');
const FinishSetup = () => import('./FinishSetup.vue');

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
          path: 'create',
          component: CreateStepWrap,
          children: [
            {
              path: '',
              name: 'chatbot_new',
              component: UploadFiles,
              roles: ['administrator'],
            },
            {
              path: 'connect_inbox',
              name: 'chatbot_connect_inbox',
              component: ConnectInbox,
              roles: ['administrator'],
            },
          ],
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
