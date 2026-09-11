import { frontendURL } from '../../../helper/URLHelper';
import KanbanView from './KanbanView.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/kanban'),
    name: 'kanban_view',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: KanbanView,
  },
];
