/* eslint arrow-body-style: 0 */
import SettingsContent from '../Wrapper';
import { frontendURL } from '../../../../helper/URLHelper';
import CsatSetting from './Index';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/csat_templates'),
      component: SettingsContent,
      props: () => {
        return {
          headerTitle: 'CSAT_TEMPLATES.HEADER',
          icon: 'star-half',
        };
      },
      children: [
        {
          path: '',
          name: 'settings_csat_templates',
          component: CsatSetting,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
