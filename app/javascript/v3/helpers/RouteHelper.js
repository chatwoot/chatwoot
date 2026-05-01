// ============================================================================
// DJC-CHAT FORK PATCH — see guides/fork-patches.md for full list
// ----------------------------------------------------------------------------
// Date:       2026-05-01
// Why:        DJC Chat authenticates users through the djcai-v3 portal instead of
//             showing Chatwoot's direct login page.
// Changes:    1. Redirect normal /app/login and /app/login/sso visits to
//                EXTERNAL_LOGIN_URL.
//             2. Keep /app/login?email=...&sso_auth_token=... available for
//                platform SSO handoff.
// Merge tip:  Keep validateSSOLoginParams ahead of the external redirect.
// ============================================================================
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

const externalLoginUrl = chatwootConfig => {
  return (
    chatwootConfig.externalLoginUrl ||
    window.globalConfig?.EXTERNAL_LOGIN_URL ||
    ''
  );
};

const redirectToExternalLogin = chatwootConfig => {
  const loginUrl = externalLoginUrl(chatwootConfig);
  if (!loginUrl) {
    return false;
  }

  window.location.assign(loginUrl);
  return true;
};

const isDirectLoginRoute = to => ['login', 'sso_login'].includes(to.name);

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

  if (isDirectLoginRoute(to) && redirectToExternalLogin(chatwootConfig)) {
    return;
  }

  // Redirect to dashboard if a cookie is present, the cookie
  // cleanup and token validation happens in the application pack.
  if (hasAuthCookie()) {
    replaceRouteWithReload(DEFAULT_REDIRECT_URL);
    return;
  }

  // If the URL is an invalid path, redirect to login page
  // Disable navigation to signup page if signups are disabled
  // Signup route has an attribute (requireSignupEnabled) in it's definition
  const isAnInalidSignupNavigation =
    chatwootConfig.signupEnabled !== 'true' &&
    to.meta &&
    to.meta.requireSignupEnabled;

  // Disable navigation to SAML login if enterprise is not enabled
  // SAML route has an attribute (requireEnterprise) in it's definition
  const isEnterpriseOnlyPath =
    chatwootConfig.isEnterprise !== 'true' &&
    to.meta &&
    to.meta.requireEnterprise;

  if (!to.name || isAnInalidSignupNavigation || isEnterpriseOnlyPath) {
    if (redirectToExternalLogin(chatwootConfig)) {
      return;
    }

    next(frontendURL('login'));
    return;
  }

  next();
};

export const isOnOnboardingView = route => {
  const { name = '' } = route || {};

  if (!name) {
    return false;
  }

  return name.includes('onboarding_');
};
