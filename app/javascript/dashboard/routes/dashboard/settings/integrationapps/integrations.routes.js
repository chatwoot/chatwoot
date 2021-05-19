import Index from './Index';
import SettingsContent from '../Wrapper';
import ShowIntegration from './ShowIntegration';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/applications'),
      component: SettingsContent,
      props: params => {
        const showBackButton = params.name !== 'settings_applications';
        const backUrl =
          params.name === 'settings_applications_integration'
            ? { name: 'settings_applications' }
            : '';
        return {
          headerTitle: 'Applications',
          icon: 'ion-asterisk',
          showBackButton,
          backUrl,
        };
      },
      children: [
        {
          path: '',
          name: 'settings_applications',
          component: Index,
          roles: ['administrator'],
        },
        {
          path: ':integration_id/',
          name: 'settings_applications_integration',
          component: ShowIntegration,
          roles: ['administrator'],
          props: route => {
            return {
              integrationId: route.params.integration_id,
              code: route.query.code,
            };
          },
        },
      ],
    },
  ],
};
