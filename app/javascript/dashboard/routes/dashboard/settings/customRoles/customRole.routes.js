import { FEATURE_FLAGS } from '../../../../featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { frontendURL } from 'dashboard/helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import CustomRolesHome from './Index.vue';
import CustomRoleForm from './CustomRoleForm.vue';

const meta = {
  featureFlag: FEATURE_FLAGS.CUSTOM_ROLES,
  installationTypes: [
    INSTALLATION_TYPES.CLOUD,
    INSTALLATION_TYPES.ENTERPRISE,
    INSTALLATION_TYPES.COMMUNITY,
  ],
  permissions: ['administrator'],
};

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/custom-roles'),
      component: SettingsWrapper,
      props: { keepAlive: false },
      children: [
        {
          path: '',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'custom_roles_list',
          meta,
          component: CustomRolesHome,
        },
        {
          path: 'new',
          name: 'custom_roles_new',
          meta,
          component: CustomRoleForm,
        },
        {
          path: ':roleId/edit',
          name: 'custom_roles_edit',
          meta,
          component: CustomRoleForm,
        },
      ],
    },
  ],
};
