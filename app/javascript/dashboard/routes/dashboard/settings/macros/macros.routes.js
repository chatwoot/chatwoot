import { frontendURL } from 'dashboard/helper/URLHelper';

import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
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
            permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/macros/:macroId/edit'),
      name: 'macros_edit',
      component: MacroEditor,
      meta: {
        permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
      },
    },
    {
      path: frontendURL('accounts/:accountId/settings/macros/new'),
      name: 'macros_new',
      component: MacroEditor,
      meta: {
        permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
      },
    },
  ],
};
