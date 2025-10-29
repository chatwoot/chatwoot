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

// Wrap router.resolve to handle errors gracefully
const originalResolve = router.resolve;
router.resolve = function (to) {
  try {
    return originalResolve.call(this, to);
  } catch (error) {
    // eslint-disable-next-line no-console
    console.warn('Router resolve error:', error);
    // Return a safe fallback route
    return {
      path: '/',
      name: undefined,
      meta: {},
      matched: [],
      params: {},
      query: {},
      hash: '',
      fullPath: '/',
    };
  }
};

export const validateAuthenticateRoutePermission = (to, next) => {
  const { isLoggedIn, getCurrentUser: user } = store.getters;

  if (!isLoggedIn) {
    window.location.assign('/app/login');
    return '';
  }

  if (!to.name) {
    return next(frontendURL(`accounts/${user.account_id}/dashboard`));
  }

  const nextRoute = validateLoggedInRoutes(to, store.getters.getCurrentUser);
  return nextRoute ? next(frontendURL(nextRoute)) : next();
};

export const initalizeRouter = () => {
  const userAuthentication = store.dispatch('setUser');

  router.beforeEach((to, _from, next) => {
    try {
      AnalyticsHelper.page(to.name || '', {
        path: to.path,
        name: to.name,
      });

      return userAuthentication
        .then(() => {
          try {
            return validateAuthenticateRoutePermission(to, next);
          } catch (error) {
            // eslint-disable-next-line no-console
            console.warn('Route validation error:', error);
            // Fallback to dashboard
            return next(
              frontendURL(
                `accounts/${store.getters.getCurrentUser?.account_id || 1}/dashboard`
              )
            );
          }
        })
        .catch(error => {
          // eslint-disable-next-line no-console
          console.warn('User authentication error:', error);
          // Fallback to login
          return next('/app/login');
        });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.warn('Router beforeEach error:', error);
      // Fallback to dashboard
      return next(
        frontendURL(
          `accounts/${store.getters.getCurrentUser?.account_id || 1}/dashboard`
        )
      );
    }
  });
};

export default router;
