import { frontendURL } from '../../../helper/URLHelper';
import TasksIndex from './pages/Index.vue';

const tasksMeta = {
  permissions: ['administrator', 'supervisor', 'agent'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/tasks'),
    name: 'tasks_dashboard',
    component: TasksIndex,
    meta: tasksMeta,
  },
];
