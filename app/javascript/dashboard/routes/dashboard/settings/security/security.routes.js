import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

// No SAML feature-flag or installation-type gate here: the page also hosts
// MFA enforcement, which self-hosted installs need. SAML gates itself in-page.
export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/security'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsWrapper,
      props: {
        headerTitle: 'SECURITY_SETTINGS.TITLE',
        icon: 'i-lucide-shield',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'security_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
