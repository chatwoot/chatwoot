import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import AssignmentPolicyIndex from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/assignment-policy'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'assignment_policy_index', params: to.params };
          },
        },
        {
          path: 'index',
          name: 'assignment_policy_index',
          component: AssignmentPolicyIndex,
          meta: {
            featureFlag: FEATURE_FLAGS.ASSIGNMENT_V2,
            permissions: ['administrator'],
          },
        },
        // {
        //   path: 'assignment-policy',
        //   name: 'assignment_policy',
        //   component: AssignmentPolicyIndex,
        //   meta: {
        //     featureFlag: FEATURE_FLAGS.ASSIGNMENT_V2,
        //     permissions: ['administrator'],
        //   },
        // },
        // {
        //   path: 'agent-capacity-policy',
        //   name: 'agent_capacity_policy',
        //   component: AssignmentPolicyIndex,
        //   meta: {
        //     featureFlag: FEATURE_FLAGS.ASSIGNMENT_V2,
        //     permissions: ['administrator'],
        //   },
        // },
      ],
    },
  ],
};
