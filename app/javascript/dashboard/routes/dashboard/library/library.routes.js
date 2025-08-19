import { frontendURL } from '../../../helper/URLHelper';

const LibraryPage = () => import('./pages/LibraryPage.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/library'),
    name: 'library_index',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: LibraryPage,
  },
];

export default {
  routes,
};
