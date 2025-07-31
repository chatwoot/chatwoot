import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import SettingsContent from '../Wrapper.vue';

// Import components (to be created)
import AssignmentSettings from './Index.vue';
import PolicyList from './policies/PolicyList.vue';
import PolicyForm from './policies/PolicyForm.vue';
import LeaveManagement from './leaves/LeaveManagement.vue';
import LeaveForm from './leaves/LeaveForm.vue';
import LeaveDetails from './leaves/LeaveDetails.vue';
import AgentCapacity from './capacity/AgentCapacity.vue';
import CapacityForm from './capacity/CapacityForm.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/assignment'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'assignment_settings',
          component: AssignmentSettings,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/assignment'),
      component: SettingsContent,
      props: {
        headerTitle: 'ASSIGNMENT_SETTINGS.HEADER',
        icon: 'assignment-alt',
        showBackButton: true,
      },
      children: [
        // Assignment Policies Routes
        {
          path: 'policies',
          name: 'assignment_policies_list',
          component: PolicyList,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'policies/new',
          name: 'assignment_policies_new',
          component: PolicyForm,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'policies/:id/edit',
          name: 'assignment_policies_edit',
          component: PolicyForm,
          meta: {
            permissions: ['administrator'],
          },
        },
        // Leave Management Routes
        {
          path: 'leaves',
          name: 'assignment_leaves_list',
          component: LeaveManagement,
          meta: {
            permissions: ['administrator', 'agent'],
          },
        },
        {
          path: 'leaves/new',
          name: 'assignment_leaves_new',
          component: LeaveForm,
          meta: {
            permissions: ['administrator', 'agent'],
          },
        },
        {
          path: 'leaves/:id',
          name: 'assignment_leaves_details',
          component: LeaveDetails,
          meta: {
            permissions: ['administrator', 'agent'],
          },
        },
        // Agent Capacity Routes (Enterprise)
        {
          path: 'capacity',
          name: 'assignment_capacity_list',
          component: AgentCapacity,
          meta: {
            permissions: ['administrator'],
            enterprise: true,
          },
        },
        {
          path: 'capacity/new',
          name: 'assignment_capacity_new',
          component: CapacityForm,
          meta: {
            permissions: ['administrator'],
            enterprise: true,
          },
        },
        {
          path: 'capacity/:id/edit',
          name: 'assignment_capacity_edit',
          component: CapacityForm,
          meta: {
            permissions: ['administrator'],
            enterprise: true,
          },
        },
      ],
    },
  ],
};
