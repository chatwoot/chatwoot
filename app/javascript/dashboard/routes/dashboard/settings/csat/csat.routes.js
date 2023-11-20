/* eslint arrow-body-style: 0 */
import SettingsContent from '../Wrapper';
import { frontendURL } from '../../../../helper/URLHelper';
import CsatSetting from './Index';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/csat'),
      component: SettingsContent,
      props: () => {
        return {
          headerTitle: 'CSAT_SETTINGS.HEADER',
          icon: 'star-half',
        };
      },
      children: [
        {
          path: '',
          name: 'settings_csat',
          component: CsatSetting,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
