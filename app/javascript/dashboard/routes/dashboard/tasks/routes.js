import { frontendURL } from '../../../helper/URLHelper';

import TaskView from './TaskView.vue';

import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from '../../../constants/permissions.js';

const taskPermissions = {
  permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/tasks'),

    name: 'tasks_dashboard_index',

    component: TaskView,

    props: () => ({ taskId: 0 }),

    meta: taskPermissions,
  },

  {
    path: frontendURL('accounts/:accountId/tasks/:taskId'),

    name: 'tasks_dashboard_show',

    component: TaskView,

    props: route => ({ taskId: route.params.taskId }),

    meta: taskPermissions,
  },
];
