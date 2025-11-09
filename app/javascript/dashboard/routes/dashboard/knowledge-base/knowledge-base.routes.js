import { frontendURL } from '../../../helper/URLHelper';

const KnowledgeBasePageRouteView = () =>
  import('./pages/KnowledgeBasePageRouteView.vue');
const ProductCatalogPage = () => import('./pages/ProductCatalogPage.vue');

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
      ],
    },
  ],
};
