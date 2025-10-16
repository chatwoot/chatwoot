import { frontendURL } from '../../../helper/URLHelper';
import SettingsContent from '../settings/Wrapper.vue';
import VoiceAgentsIndex from './Index.vue';
import VoiceAgentForm from './Form.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/voice-agents'),
      component: SettingsContent,
      props: {
        headerTitle: 'VOICE_AGENTS.HEADER',
        icon: 'phone-call',
        showBackButton: false,
      },
      children: [
        {
          path: '',
          name: 'vapi_agents_index',
          component: VoiceAgentsIndex,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'new',
          name: 'vapi_agents_new',
          component: VoiceAgentForm,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: ':id/edit',
          name: 'vapi_agents_edit',
          component: VoiceAgentForm,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};


