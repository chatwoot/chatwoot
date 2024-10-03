import { frontendURL } from '../../../../helper/URLHelper';
import { defineAsyncComponent } from 'vue';

const SettingsWrapper = defineAsyncComponent(
  () => import('../SettingsWrapper.vue')
);
const Automation = defineAsyncComponent(() => import('./Index.vue'));

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/automation'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'automation_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'automation_list',
          component: Automation,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
