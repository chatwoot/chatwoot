// Add to app/javascript/dashboard/routes/dashboard/dashboard.routes.js:
//   import kanbanRoutes from 'kanban/routes/kanban.routes';
//   ...
//   children: [ ...kanbanRoutes, ... ]
import { frontendURL } from 'dashboard/helper/URLHelper';

const BoardsIndex = () => import('../components/BoardsIndex.vue');
const BoardView   = () => import('../components/BoardView.vue');

export default [
  {
    path: frontendURL('accounts/:accountId/kanban'),
    name: 'kanban_boards_index',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: BoardsIndex,
  },
  {
    path: frontendURL('accounts/:accountId/kanban/:boardId'),
    name: 'kanban_board_view',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: BoardView,
  },
];
