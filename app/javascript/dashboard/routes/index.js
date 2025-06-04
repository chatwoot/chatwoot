import { createRouter, createWebHistory } from 'vue-router';

import { frontendURL } from '../helper/URLHelper';
import dashboard from './dashboard/dashboard.routes';
import store from 'dashboard/store';
import { validateLoggedInRoutes } from '../helper/routeHelpers';
import AnalyticsHelper from '../helper/AnalyticsHelper';
import { buildPermissionsFromRouter } from '../helper/permissionsHelper';

const routes = [...dashboard.routes];

export const router = createRouter({ history: createWebHistory(), routes });
export const routesWithPermissions = buildPermissionsFromRouter(routes);

export const validateAuthenticateRoutePermission = async (to, next) => {
  const { isLoggedIn, getCurrentUser: user } = store.getters;

  if (!isLoggedIn) {
    window.location.assign('/app/pricing');
    // window.location.assign('/app/login');
    return '';
  }

  if (!to.name) {
    return next(frontendURL(`accounts/${user.account_id}/dashboard`));
  }

  // UNCOMMENT THIS FEATURE FOR RESTRICT USER MUST HAVE ACTVIE SUBSCRIPTION TO ACCESS MENUS
  // // Exclude halaman tertentu agar tidak dicek (misalnya billing)
  // const exemptedPrefixes = ['billing', 'account_suspended'];
  // const isExempted = exemptedPrefixes.some(prefix => to.name?.startsWith(prefix));
  // if (!isExempted) {
  //   // Lakukan pengecekan subscription
  //   const { data } = await axios.get(`api/v1/accounts/${user.account_id}/subscriptions/status`);
  //   if (!data.active) {
  //     return next({
  //       name: 'billing_settings_index',
  //       params: { accountId: user.account_id },
  //       query: { expired: 'true' },
  //     });
  //   }
  // }

  const nextRoute = validateLoggedInRoutes(to, store.getters.getCurrentUser);
  return nextRoute ? next(frontendURL(nextRoute)) : next();
};

export const initalizeRouter = () => {
  const userAuthentication = store.dispatch('setUser');

  router.beforeEach((to, _from, next) => {
    AnalyticsHelper.page(to.name || '', {
      path: to.path,
      name: to.name,
    });

    userAuthentication.then(() => {
      return validateAuthenticateRoutePermission(to, next, store);
    });
  });
};
// export const initalizeRouter = () => {
//   const userAuthentication = store.dispatch('setUser');

//   router.beforeEach(async (to, _from, next) => {
//     AnalyticsHelper.page(to.name || '', {
//       path: to.path,
//       name: to.name,
//     });

//     try {
//       await userAuthentication;

//       const { isLoggedIn, getCurrentUser: user } = store.getters;

//       if (!isLoggedIn) {
//         return window.location.assign('/app/pricing'); // Atau /app/login
//       }

//       if (!to.name) {
//         return next(frontendURL(`accounts/${user.account_id}/dashboard`));
//       }

//       // Exclude halaman tertentu agar tidak dicek (misalnya billing)
//       const exemptedRoutes = ['billing', 'account_suspended'];
//       if (!exemptedRoutes.includes(to.name)) {
//         // Lakukan pengecekan subscription
//         const { data } = await axios.get(`accounts/${user.account_id}/subscriptions/status`);
//         if (!data.active) {
//           alert('Subscription Anda telah berakhir. Silakan perpanjang.');
//           return next(frontendURL(`accounts/${user.account_id}/settings/billing`));
//         }
//       }

//       // Lanjutkan route normal
//       const nextRoute = validateLoggedInRoutes(to, user);
//       return nextRoute ? next(frontendURL(nextRoute)) : next();

//     } catch (err) {
//       console.error('Router init error:', err);
//       return window.location.assign('/app/login');
//     }
//   });
// };

export default router;
