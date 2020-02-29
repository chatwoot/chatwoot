import Index from './Index';
import SettingsContent from '../Wrapper';
import Webhook from './Webhook';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('settings/integrations'),
      component: SettingsContent,
      props: params => {
        const showBackButton = params.name !== 'settings_integrations';
        return {
          headerTitle: 'INTEGRATION_SETTINGS.HEADER',
          icon: 'ion-flash',
          showBackButton,
        };
      },
      children: [
        {
          path: '',
          name: 'settings_integrations',
          component: Index,
          roles: ['administrator'],
        },
        {
          path: 'webhook',
          component: Webhook,
          name: 'settings_integrations_webhook',
          roles: ['administrator'],
        },
      ],
    },
  ],
};
