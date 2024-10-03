import { frontendURL } from '../../../../helper/URLHelper';
import { defineAsyncComponent } from 'vue';

const SettingsWrapper = defineAsyncComponent(
  () => import('../SettingsWrapper.vue')
);
const Index = defineAsyncComponent(() => import('./Index.vue'));

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/sla'),
      component: SettingsWrapper,
      props: {},
      children: [
        {
          path: '',
          name: 'sla_wrapper',
          meta: {
            permissions: ['administrator'],
          },
          redirect: to => {
            return { name: 'sla_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'sla_list',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};
