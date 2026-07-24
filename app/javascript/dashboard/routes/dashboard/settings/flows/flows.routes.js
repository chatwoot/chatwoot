import { frontendURL } from 'dashboard/helper/URLHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { ROLES } from 'dashboard/constants/permissions.js';
import SettingsWrapper from '../SettingsWrapper.vue';
import SettingsContent from '../Wrapper.vue';
import FlowsIndex from './Index.vue';
import FlowEdit from './Edit.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/flows'),
      component: SettingsWrapper,
      props: { wide: true },
      children: [
        {
          path: '',
          name: 'flows_index',
          component: FlowsIndex,
          meta: {
            featureFlag: FEATURE_FLAGS.FLOWS_V1,
            permissions: ROLES,
          },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/flows'),
      component: SettingsContent,
      props: () => ({
        headerTitle: 'FLOWS.HEADER',
        icon: 'git-branch',
        showBackButton: true,
      }),
      children: [
        {
          path: 'new',
          name: 'flows_new',
          component: FlowEdit,
          meta: {
            featureFlag: FEATURE_FLAGS.FLOWS_V1,
            permissions: ROLES,
          },
        },
        {
          path: ':flowId/edit',
          name: 'flows_edit',
          component: FlowEdit,
          meta: {
            featureFlag: FEATURE_FLAGS.FLOWS_V1,
            permissions: ROLES,
          },
        },
      ],
    },
  ],
};
