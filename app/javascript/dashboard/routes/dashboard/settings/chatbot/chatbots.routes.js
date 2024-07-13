import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const Index = () => import('./Index.vue');
const ChatbotEdit = () => import('./Edit/Index.vue');
const CreateStepWrap = () => import('./Create/Index.vue');
const UploadFiles = () => import('./Create/FileUploader.vue');
const ConnectInbox = () => import('./Create/ConnectInbox.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/chatbots'),
      roles: ['administrator'],
      component: SettingsContent,
      props: {
        headerTitle: 'CHATBOTS.HEADER',
        icon: 'chatbot-icon',
        showNewButton: true,
      },
      children: [
        {
          path: '',
          name: 'chatbots_index',
          component: Index,
          roles: ['administrator'],
        },
        {
          path: 'create',
          component: CreateStepWrap,
          children: [
            {
              path: '',
              name: 'chatbots_new',
              component: UploadFiles,
              roles: ['administrator'],
            },
            {
              path: 'connect_inbox',
              name: 'chatbots_connect_inbox',
              component: ConnectInbox,
              roles: ['administrator'],
            },
          ],
        },
        {
          path: 'edit/:chatbotId',
          name: 'chatbots_edit',
          component: ChatbotEdit,
          roles: ['administrator'],
          props: true, // Pass route parameters as props
        },
      ],
    },
  ],
};
