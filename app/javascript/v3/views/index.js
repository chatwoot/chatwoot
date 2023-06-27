import VueRouter from 'vue-router';

import { frontendURL } from 'dashboard/helper/URLHelper';
import { clearBrowserSessionCookies } from 'dashboard/store/utils/api';
import routes from './routes';
import AnalyticsHelper from 'dashboard/helper/AnalyticsHelper';
import { redirectIfAuthCookieExist } from '../helpers/AuthHelper';

export const router = new VueRouter({ mode: 'history', routes });

const validateSSOLoginParams = to => {
  const isLoginRoute = to.name === 'login';
  const { email, sso_auth_token: ssoAuthToken } = to.query || {};
  const hasValidSSOParams = email && ssoAuthToken;
  return isLoginRoute && hasValidSSOParams;
};

export const validateRouteAccess = (to, from, next) => {
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

  return next();
};

export const initalizeRouter = () => {
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

    redirectIfAuthCookieExist();

    if (!to.name) {
      next(frontendURL('login'));
      return;
    }

    validateRouteAccess(to, from, next);
  });
};

export default router;
