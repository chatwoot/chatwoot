import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import LeadRetargetingIndex from './Index.vue';
import LeadRetargetingForm from './Form.vue';
import LeadRetargetingShow from './Show.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/copilots'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'copilots_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'copilots_list',
          component: LeadRetargetingIndex,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'new',
          name: 'copilots_new',
          component: LeadRetargetingForm,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: ':sequenceId/edit',
          name: 'copilots_edit',
          component: LeadRetargetingForm,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: ':sequenceId/show',
          name: 'copilots_show',
          component: LeadRetargetingShow,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
