import { frontendURL } from '../../../../helper/URLHelper';
const Chatbots = () => import('./Index.vue');
const ChatbotSetting = () => import('./Settings.vue');
const CreateStepWrap = () => import('./Create/Index.vue');
const UploadFiles = () => import('./Create/FileUploader.vue');
const ConnectInbox = () => import('./Create/ConnectInbox.vue');
const SettingsContent = () => import('../Wrapper.vue');
const SettingsWrapper = () => import('../SettingsWrapper.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/chatbots'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'chatbots_wrapper',
          component: Chatbots,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/chatbots'),
      component: SettingsContent,
      props: () => {
        return {
          headerTitle: 'CHATBOTS.HEADER',
          icon: 'chatbot-icon',
          showBackButton: true,
        };
      },
      children: [
        {
          path: 'create',
          component: CreateStepWrap,
          children: [
            {
              path: '',
              name: 'chatbots_new',
              component: UploadFiles,
              meta: {
                permissions: ['administrator'],
              },
            },
            {
              path: 'connect_inbox',
              name: 'chatbots_connect_inbox',
              component: ConnectInbox,
              meta: {
                permissions: ['administrator'],
              },
            },
          ],
        },
        {
          path: ':chatbotId',
          name: 'chatbots_setting',
          component: ChatbotSetting,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
