import VueRouter from 'vue-router';

import { frontendURL } from '../helper/URLHelper';
import { clearBrowserSessionCookies } from '../store/utils/api';
import authRoute from './auth/auth.routes';
import dashboard from './dashboard/dashboard.routes';
import login from './login/login.routes';
import store from '../store';
import { validateLoggedInRoutes } from '../helper/routeHelpers';
import AnalyticsHelper from '../helper/AnalyticsHelper';

const routes = [...login.routes, ...dashboard.routes, ...authRoute.routes];

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

const unProtectedRoutes = ['login', 'auth_signup', 'auth_reset_password'];

const authIgnoreRoutes = [
  'auth_confirmation',
  'pushBack',
  'auth_password_edit',
];

const routeValidators = [
  {
    protected: false,
    loggedIn: true,
    handler: (_, getters) => {
      const user = getters.getCurrentUser;
      return `accounts/${user.account_id}/dashboard`;
    },
  },
  {
    protected: true,
    loggedIn: false,
    handler: () => 'login',
  },
  {
    protected: true,
    loggedIn: true,
    handler: (to, getters) =>
      validateLoggedInRoutes(to, getters.getCurrentUser, window.roleWiseRoutes),
  },
  {
    protected: false,
    loggedIn: false,
    handler: () => null,
  },
];

export const validateAuthenticateRoutePermission = (
  to,
  from,
  next,
  { getters }
) => {
  const isLoggedIn = getters.isLoggedIn;
  const isProtectedRoute = !unProtectedRoutes.includes(to.name);
  const strategy = routeValidators.find(
    validator =>
      validator.protected === isProtectedRoute &&
      validator.loggedIn === isLoggedIn
  );
  const nextRoute = strategy.handler(to, getters);
  return nextRoute ? next(frontendURL(nextRoute)) : next();
};

const validateSSOLoginParams = to => {
  const isLoginRoute = to.name === 'login';
  const { email, sso_auth_token: ssoAuthToken } = to.query || {};
  const hasValidSSOParams = email && ssoAuthToken;
  return isLoginRoute && hasValidSSOParams;
};

export const validateRouteAccess = (to, from, next, { getters }) => {
  // Disable navigation to signup page if signups are disabled
  // Signup route has an attribute (requireSignupEnabled)
  // defined in it's route definition
  if (
    window.chatwootConfig.signupEnabled !== 'true' &&
    to.meta &&
    to.meta.requireSignupEnabled
  ) {
    return next(frontendURL('login'));
  }

  // For routes which doesn't care about authentication, skip validation
  if (authIgnoreRoutes.includes(to.name)) {
    return next();
  }

  return validateAuthenticateRoutePermission(to, from, next, { getters });
};

export const initalizeRouter = () => {
  const userAuthentication = store.dispatch('setUser');
  router.beforeEach((to, from, next) => {
    AnalyticsHelper.page(to.name || '', {
      path: to.path,
      name: to.name,
    });

    if (validateSSOLoginParams(to)) {
      clearBrowserSessionCookies();
      next();
      return;
    }

    userAuthentication.then(() => {
      if (!to.name) {
        const { isLoggedIn, getCurrentUser: user } = store.getters;
        if (isLoggedIn) {
          return next(frontendURL(`accounts/${user.account_id}/dashboard`));
        }
        return next('/app/login');
      }

      return validateRouteAccess(to, from, next, store);
    });
  });
};

export default router;
