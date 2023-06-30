import { frontendURL } from 'dashboard/helper/URLHelper';
import { clearBrowserSessionCookies } from 'dashboard/store/utils/api';
import { hasAuthCookie } from './AuthHelper';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import { replaceRouteWithReload } from './CommonHelper';

const validateSSOLoginParams = to => {
  const isLoginRoute = to.name === 'login';
  const { email, sso_auth_token: ssoAuthToken } = to.query || {};
  const hasValidSSOParams = email && ssoAuthToken;
  return isLoginRoute && hasValidSSOParams;
};

export const validateRouteAccess = (to, next, chatwootConfig = {}) => {
  // Pages with ignoreSession:true would be rendered
  // even if there is an active session
  // Used for confirmation or password reset pages
  if (to.meta && to.meta.ignoreSession) {
    next();
    return;
  }

  if (validateSSOLoginParams(to)) {
    clearBrowserSessionCookies();
    next();
    return;
  }

  // Redirect to dashboard if a cookie is present, the cookie
  // cleanup and token validation happens in the application pack.
  if (hasAuthCookie()) {
    replaceRouteWithReload(DEFAULT_REDIRECT_URL);
    return;
  }

  // If the URL is an invalid path, redirect to login page
  if (!to.name) {
    next(frontendURL('login'));
    return;
  }

  // Disable navigation to signup page if signups are disabled
  // Signup route has an attribute (requireSignupEnabled) in it's definition
  if (
    chatwootConfig.signupEnabled !== 'true' &&
    to.meta &&
    to.meta.requireSignupEnabled
  ) {
    next(frontendURL('login'));
    return;
  }

  next();
};
