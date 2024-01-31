import VueRouter from 'vue-router';

import { frontendURL } from '../helper/URLHelper';
import dashboard from './dashboard/dashboard.routes';
import store from '../store';
import { validateLoggedInRoutes } from '../helper/routeHelpers';
import AnalyticsHelper from '../helper/AnalyticsHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const routes = [...dashboard.routes];

window.roleWiseRoutes = {
  agent: [],
  administrator: [],
};

// generateRoleWiseRoute - updates window object with agent/admin route
const generateRoleWiseRoute = route => {
  route.forEach(element => {
    if (element.children) {
      generateRoleWiseRoute(element.children);
    }
    if (element.roles) {
      element.roles.forEach(roleEl => {
        window.roleWiseRoutes[roleEl].push(element.name);
      });
    }
  });
};
// Create a object of routes
// accessible by each role.
// returns an object with roles as keys and routeArr as values
generateRoleWiseRoute(routes);

export const router = new VueRouter({ mode: 'history', routes });

export const validateAuthenticateRoutePermission = (to, next, { getters }) => {
  const { isLoggedIn, getCurrentUser: user } = getters;

  if (!isLoggedIn) {
    window.location = '/app/login';
    return '/app/login';
  }

  // Open inbox view if inbox view feature is enabled, else redirect to dashboard
  // TODO: Remove this code once inbox view feature is enabled for all accounts
  const isInboxViewEnabled = store.getters['accounts/isFeatureEnabledGlobally'](
    user.account_id,
    FEATURE_FLAGS.INBOX_VIEW
  );
  if (to.name === 'inbox_index' && !isInboxViewEnabled) {
    return next(frontendURL(`accounts/${user.account_id}/dashboard`));
  }

  if (!to.name) {
    return next(frontendURL(`accounts/${user.account_id}/dashboard`));
  }

  const nextRoute = validateLoggedInRoutes(
    to,
    getters.getCurrentUser,
    window.roleWiseRoutes
  );
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
