import { frontendURL } from '../../../helper/URLHelper';
import CatalogIndex from 'dashboard/components-next/catalog/CatalogIndex.vue';

const meta = {
  permissions: ['administrator', 'agent'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/catalog'),
    name: 'catalog_index',
    component: CatalogIndex,
    meta,
  },
];
