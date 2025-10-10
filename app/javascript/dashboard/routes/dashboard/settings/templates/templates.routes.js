import { frontendURL } from '../../../../helper/URLHelper';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import SettingsWrapper from '../SettingsWrapper.vue';
import TemplateList from './Index.vue';
import TemplateBuilder from './TemplateBuilder.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/templates'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'templates_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'templates_list',
          meta: {
            permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          },
          component: TemplateList,
        },
        {
          path: 'new',
          name: 'template_new',
          meta: {
            permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          },
          component: TemplateBuilder,
        },
        {
          path: ':templateId/edit',
          name: 'template_edit',
          meta: {
            permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          },
          component: TemplateBuilder,
        },
      ],
    },
  ],
};
