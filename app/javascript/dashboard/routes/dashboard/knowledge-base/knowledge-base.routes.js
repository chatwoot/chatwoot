import { frontendURL } from '../../../helper/URLHelper';

const KnowledgeBasePageRouteView = () =>
  import('./pages/KnowledgeBasePageRouteView.vue');
const ProductCatalogPage = () => import('./pages/ProductCatalogPage.vue');
const UploadHistoryPage = () => import('./pages/UploadHistoryPage.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/knowledge-base'),
      component: KnowledgeBasePageRouteView,
      children: [
        {
          path: 'products',
          name: 'knowledge_base_products',
          meta: {
            permissions: ['administrator'],
          },
          component: ProductCatalogPage,
        },
        {
          path: 'upload-history',
          name: 'knowledge_base_upload_history',
          meta: {
            permissions: ['administrator'],
          },
          component: UploadHistoryPage,
        },
      ],
    },
  ],
};
