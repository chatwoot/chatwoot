import { createRouter, createWebHistory } from 'vue-router';

import { frontendURL } from '../helper/URLHelper';
import dashboard from './dashboard/dashboard.routes';
import store from 'dashboard/store';
import { validateLoggedInRoutes } from '../helper/routeHelpers';
import { isOnOnboardingView } from 'v3/helpers/RouteHelper';
import AnalyticsHelper from '../helper/AnalyticsHelper';
import AcceptInvitation from 'v3/views/auth/accept-invitation/Index.vue';

const ONBOARDING_STEPS = ['account_details', 'enrichment'];
const publicRoutes = [
  {
    path: '/accept-invitation',
    name: 'accept_invitation',
    component: AcceptInvitation,
    meta: { ignoreSession: true },
    props: route => ({
      token: route.query.token,
      clientId: route.query.client_id,
    }),
  },
];

const routes = [...publicRoutes, ...dashboard.routes];

export const router = createRouter({ history: createWebHistory(), routes });

const syncDocumentTitle = () => {
  const installationName = window.globalConfig?.INSTALLATION_NAME;
  if (installationName) {
    document.title = installationName;
  }
};

const getSsoCredentials = to => {
  const {
    email,
    sso_auth_token: ssoAuthToken,
    redirect_to: redirectTo,
  } = to.query || {};
  if (!email || !ssoAuthToken) return null;

  return { email, ssoAuthToken, redirectTo };
};

const isSafeAppRedirect = redirectTo =>
  typeof redirectTo === 'string' && redirectTo.startsWith('/app/');

const defaultAuthenticatedRoute = user => {
  const accountId = user?.account_id || user?.accounts?.[0]?.id;
  return accountId
    ? frontendURL(`accounts/${accountId}/dashboard`)
    : frontendURL('no-accounts');
};

export const validateAuthenticateRoutePermission = async (to, next) => {
  if (to.meta?.ignoreSession) {
    return next();
  }

  const { isLoggedIn, getCurrentUser: user } = store.getters;
  const ssoCredentials = getSsoCredentials(to);

  if (!isLoggedIn && ssoCredentials) {
    try {
      const currentUser = await store.dispatch('loginWithSso', ssoCredentials);
      if (isSafeAppRedirect(ssoCredentials.redirectTo)) {
        return next(ssoCredentials.redirectTo);
      }
      return next(defaultAuthenticatedRoute(currentUser));
    } catch {
      window.location.assign('/app/login?error=autonomia-sso-error');
      return '';
    }
  }

  if (!isLoggedIn) {
    if (window.chatwootConfig?.autonomiaSsoAutoRedirect === 'true') {
      const returnTo = encodeURIComponent(to.fullPath || '/app');
      window.location.assign(`/auth/autonomia?return_to=${returnTo}`);
      return '';
    }
    window.location.assign('/app/login');
    return '';
  }

  const { accounts = [], account_id: accountId } = user;

  if (!accounts.length) {
    if (to.name === 'no_accounts') {
      return next();
    }
    return next(frontendURL('no-accounts'));
  }

  const routeAccountId = Number(to.params?.accountId || accountId);
  const userAccount = accounts.find(a => a.id === routeAccountId);
  const isAdmin = userAccount?.role === 'administrator';
  const isActive = userAccount?.status === 'active';
  const needsOnboarding =
    ONBOARDING_STEPS.includes(userAccount?.onboarding_step) &&
    isAdmin &&
    isActive;

  if (to.name === 'no_accounts' || !to.name) {
    const target = needsOnboarding ? 'onboarding' : 'dashboard';
    return next(frontendURL(`accounts/${routeAccountId}/${target}`));
  }

  if (needsOnboarding && !isOnOnboardingView(to)) {
    return next(frontendURL(`accounts/${routeAccountId}/onboarding`));
  }
  if (!needsOnboarding && isOnOnboardingView(to)) {
    return next(frontendURL(`accounts/${routeAccountId}/dashboard`));
  }

  const nextRoute = validateLoggedInRoutes(to, store.getters.getCurrentUser);
  return nextRoute ? next(frontendURL(nextRoute)) : next();
};

export const initalizeRouter = () => {
  const userAuthentication = store.dispatch('setUser');
  syncDocumentTitle();

  router.beforeEach(async (to, _from, next) => {
    AnalyticsHelper.page(to.name || '', {
      path: to.path,
      name: to.name,
    });

    await userAuthentication;
    await validateAuthenticateRoutePermission(to, next, store);
  });

  router.afterEach(syncDocumentTitle);
};

export default router;
