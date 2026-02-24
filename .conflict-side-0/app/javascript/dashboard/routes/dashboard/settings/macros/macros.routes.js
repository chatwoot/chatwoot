import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from 'dashboard/helper/URLHelper';

import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import SettingsContent from '../Wrapper.vue';
import SettingsWrapper from '../SettingsWrapper.vue';
import Macros from './Index.vue';
import MacroEditor from './MacroEditor.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/macros'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'macros_wrapper',
          component: Macros,
          meta: {
            featureFlag: FEATURE_FLAGS.MACROS,
            permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/macros'),
      component: SettingsContent,
      props: () => {
        return {
          headerTitle: 'MACROS.HEADER',
          icon: 'flash-settings',
          showBackButton: true,
        };
      },
      children: [
        {
          path: ':macroId/edit',
          name: 'macros_edit',
          component: MacroEditor,
          meta: {
            featureFlag: FEATURE_FLAGS.MACROS,
            permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          },
        },
        {
          path: 'new',
          name: 'macros_new',
          component: MacroEditor,
          meta: {
            featureFlag: FEATURE_FLAGS.MACROS,
            permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          },
        },
      ],
    },
  ],
};
