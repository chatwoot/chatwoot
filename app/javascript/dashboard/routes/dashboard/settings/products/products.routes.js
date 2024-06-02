import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const ProductsHome = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/products'),
      component: SettingsContent,
      props: {
        headerTitle: 'PRODUCTS_MGMT.HEADER',
        icon: 'briefcase',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'products_wrapper',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'products_list',
          component: ProductsHome,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
