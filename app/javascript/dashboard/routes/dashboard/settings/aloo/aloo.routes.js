import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';

import SettingsContent from '../Wrapper.vue';
import SettingWrapper from '../SettingsWrapper.vue';

const Index = () => import('./Index.vue');
const Settings = () => import('./Settings.vue');

const meta = {
  featureFlag: FEATURE_FLAGS.ALOO,
  permissions: ['administrator'],
};

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/aloo'),
      component: SettingWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'settings_aloo_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'settings_aloo_list',
          component: Index,
          meta,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/aloo'),
      component: SettingsContent,
      props: params => {
        const showBackButton = params.name !== 'settings_aloo_list';
        const fullWidth = params.name === 'settings_aloo_edit';
        return {
          headerTitle: 'ALOO.HEADER',
          icon: 'bot',
          showBackButton,
          fullWidth,
        };
      },
      children: [
        {
          path: ':assistantId/:tab?',
          name: 'settings_aloo_edit',
          component: Settings,
          meta,
        },
      ],
    },
  ],
};
