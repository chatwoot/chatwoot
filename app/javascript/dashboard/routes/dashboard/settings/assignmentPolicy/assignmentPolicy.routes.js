import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import AssignmentPolicyIndex from './Index.vue';
import AgentAssignmentIndex from './pages/AgentAssignmentIndexPage.vue';
import AgentAssignmentCreate from './pages/AgentAssignmentCreatePage.vue';
import AgentAssignmentEdit from './pages/AgentAssignmentEditPage.vue';
import AgentCapacityIndex from './pages/AgentCapacityIndexPage.vue';
import AgentCapacityCreate from './pages/AgentCapacityCreatePage.vue';
import AgentCapacityEdit from './pages/AgentCapacityEditPage.vue';

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
        {
          path: 'assignment',
          name: 'agent_assignment_policy_index',
          component: AgentAssignmentIndex,
          meta: {
            featureFlag: FEATURE_FLAGS.ASSIGNMENT_V2,
            permissions: ['administrator'],
          },
        },
        {
          path: 'assignment/create',
          name: 'agent_assignment_policy_create',
          component: AgentAssignmentCreate,
          meta: {
            featureFlag: FEATURE_FLAGS.ASSIGNMENT_V2,
            permissions: ['administrator'],
          },
        },
        {
          path: 'assignment/edit/:id',
          name: 'agent_assignment_policy_edit',
          component: AgentAssignmentEdit,
          meta: {
            featureFlag: FEATURE_FLAGS.ASSIGNMENT_V2,
            permissions: ['administrator'],
          },
        },
        {
          path: 'capacity',
          name: 'agent_capacity_policy_index',
          component: AgentCapacityIndex,
          meta: {
            featureFlag: FEATURE_FLAGS.ADVANCED_ASSIGNMENT,
            permissions: ['administrator'],
          },
        },
        {
          path: 'capacity/create',
          name: 'agent_capacity_policy_create',
          component: AgentCapacityCreate,
          meta: {
            featureFlag: FEATURE_FLAGS.ADVANCED_ASSIGNMENT,
            permissions: ['administrator'],
          },
        },
        {
          path: 'capacity/edit/:id',
          name: 'agent_capacity_policy_edit',
          component: AgentCapacityEdit,
          meta: {
            featureFlag: FEATURE_FLAGS.ADVANCED_ASSIGNMENT,
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
