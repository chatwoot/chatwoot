import Index from './Index';
import SettingsContent from '../Wrapper';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('settings/webhooks'),
      component: SettingsContent,
      props: {
        headerTitle: 'WEBHOOKS_SETTINGS.HEADER',
        icon: 'ion-flash',
      },
      children: [
        {
          path: '',
          name: 'webhook_settings',
          component: Index,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
