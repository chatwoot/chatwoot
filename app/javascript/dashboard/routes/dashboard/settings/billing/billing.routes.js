import { frontendURL } from '../../../../helper/URLHelper';

// The enterprise billing page was removed with the enterprise edition, but the
// sidebar, paywall banners and the suspended-account page still link here.
// Keep the route name alive and send administrators to account settings instead
// of letting vue-router throw "No match".
export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/billing'),
      name: 'billing_settings_index',
      meta: {
        permissions: ['administrator'],
      },
      redirect: to => ({ name: 'general_settings_index', params: to.params }),
    },
  ],
};
