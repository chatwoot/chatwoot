import { frontendURL } from '../../../helper/URLHelper';

const KanbanBoard = () => import('./components/KanbanBoard.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/kanban'),
      name: 'kanban-board',
      component: KanbanBoard,
      meta: {
        permissions: ['administrator', 'agent', 'custom_role'],
      },
    },
  ],
};
