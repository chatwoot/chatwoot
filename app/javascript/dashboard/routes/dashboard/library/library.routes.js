import { frontendURL } from '../../../helper/URLHelper';

const LibraryPage = () => import('./pages/LibraryPage.vue');
const LibraryResourceFormPage = () =>
  import('./pages/LibraryResourceFormPage.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/library'),
    name: 'library_index',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: LibraryPage,
  },
  {
    path: frontendURL('accounts/:accountId/library/new'),
    name: 'library_resource_new',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: LibraryResourceFormPage,
  },
  {
    path: frontendURL('accounts/:accountId/library/:id/edit'),
    name: 'library_resource_edit',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: LibraryResourceFormPage,
  },
];

export default {
  routes,
};
