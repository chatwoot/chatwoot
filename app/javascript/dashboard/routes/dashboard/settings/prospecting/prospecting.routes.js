import { frontendURL } from '../../../../helper/URLHelper';
import store from '../../../../store';
import SettingsWrapper from '../SettingsWrapper.vue';

const ProspectingSettingsPage = () =>
  import('../../autonomia/prospecting/pages/ProspectingSettingsPage.vue');

const ensureProspectingEnabled = (to, _from, next) => {
  const accountId = Number(to.params.accountId);
  const account = store.getters['accounts/getAccount'](accountId);

  if (account?.autonomia_prospecting_enabled === true) {
    next();
    return;
  }

  next({ name: 'home', params: to.params });
};

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/prospecting'),
      meta: {
        permissions: ['administrator'],
      },
      beforeEnter: ensureProspectingEnabled,
      component: SettingsWrapper,
      props: {
        headerTitle: 'PROSPECTING.SETTINGS.TITLE',
        icon: 'i-lucide-search',
      },
      children: [
        {
          path: '',
          name: 'settings_prospecting_index',
          component: ProspectingSettingsPage,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
