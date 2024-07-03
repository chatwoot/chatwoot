import VueRouter from 'vue-router';

import { frontendURL } from '../helper/URLHelper';
import dashboard from './dashboard/dashboard.routes';
import store from '../store';
import { validateLoggedInRoutes } from '../helper/routeHelpers';
import AnalyticsHelper from '../helper/AnalyticsHelper';
import { buildPermissionsFromRouter } from '../helper/permissionsHelper';

const routes = [...dashboard.routes];

export const router = new VueRouter({ mode: 'history', routes });
export const routesWithPermissions = buildPermissionsFromRouter(routes);

export const validateAuthenticateRoutePermission = (to, next, { getters }) => {
  const { isLoggedIn, getCurrentUser: user } = getters;

  if (!isLoggedIn) {
    window.location = '/app/login';
    return '/app/login';
  }

  if (!to.name) {
    return next(frontendURL(`accounts/${user.account_id}/dashboard`));
  }

  const nextRoute = validateLoggedInRoutes(to, getters.getCurrentUser);
  return nextRoute ? next(frontendURL(nextRoute)) : next();
};

export const initalizeRouter = () => {
  const userAuthentication = store.dispatch('setUser');

  router.beforeEach((to, from, next) => {
    AnalyticsHelper.page(to.name || '', {
      path: to.path,
      name: to.name,
    });

    userAuthentication.then(() => {
      return validateAuthenticateRoutePermission(to, next, store);
    });
  });
};

export default router;
