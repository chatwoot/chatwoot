import { createRouter, createWebHistory } from 'vue-router';

import { frontendURL } from '../helper/URLHelper';
import dashboard from './dashboard/dashboard.routes';
import store from 'dashboard/store';
import { validateLoggedInRoutes } from '../helper/routeHelpers';
import { isOnOnboardingView } from 'v3/helpers/RouteHelper';
import {
  getShopifyShopFromRedirect,
  getTargetAccount,
  isShopifyBillingAccount,
  requiresShopifyBilling,
} from 'v3/helpers/AuthHelper';
import AnalyticsHelper from '../helper/AnalyticsHelper';

const ONBOARDING_STEPS = ['account_details', 'enrichment', 'inbox_setup'];
const routes = [...dashboard.routes];

const onboardingPath = step =>
  step === 'inbox_setup' ? 'onboarding/inbox-setup' : 'onboarding';

const shopifyBillingRedirect = query => {
  const { plan_handle: planHandle, shop } = query || {};
  if (!shop) return '';

  const params = new URLSearchParams();
  if (planHandle) params.set('plan_handle', planHandle);
  params.set('shop', shop);
  return `settings/billing?${params.toString()}`;
};

export const router = createRouter({ history: createWebHistory(), routes });

export const validateAuthenticateRoutePermission = async (to, next) => {
  const { isLoggedIn, getCurrentUser: user } = store.getters;

  if (!isLoggedIn) {
    const billingRedirect = shopifyBillingRedirect(to.query);
    const loginParams = new URLSearchParams();
    if (billingRedirect) {
      if (to.params?.accountId) {
        loginParams.set('sso_account_id', to.params.accountId);
      }
      loginParams.set('redirect_url', billingRedirect);
    }
    const loginUrl = loginParams.size
      ? `/app/login?${loginParams.toString()}`
      : '/app/login';
    window.location.assign(loginUrl);
    return '';
  }

  const { accounts = [], account_id: accountId } = user;

  if (!accounts.length) {
    if (to.name === 'no_accounts') {
      return next();
    }
    return next(frontendURL('no-accounts'));
  }

  const requestedRedirectUrl = to.query?.redirect_url;
  const pricingRedirectUrl = shopifyBillingRedirect(to.query);
  const targetRedirectUrl = requestedRedirectUrl || pricingRedirectUrl;
  const redirectAccount = getTargetAccount({
    redirectUrl: targetRedirectUrl,
    user,
  });
  if (
    !to.params?.accountId &&
    getShopifyShopFromRedirect(targetRedirectUrl) &&
    !redirectAccount
  ) {
    return next(frontendURL(`accounts/${accountId}/dashboard`));
  }

  const routeAccountId = Number(
    to.params?.accountId || redirectAccount?.id || accountId
  );
  const userAccount = accounts.find(a => a.id === routeAccountId);
  const isAdmin = userAccount?.role === 'administrator';
  const isActive = userAccount?.status === 'active';
  const needsShopifyBilling = isAdmin && requiresShopifyBilling(userAccount);
  const billingRedirect =
    isAdmin && isShopifyBillingAccount(userAccount)
      ? shopifyBillingRedirect(to.query)
      : '';
  const needsOnboarding =
    ONBOARDING_STEPS.includes(userAccount?.onboarding_step) &&
    isAdmin &&
    isActive &&
    !needsShopifyBilling;

  if (to.name === 'no_accounts' || !to.name) {
    if (billingRedirect) {
      return next(frontendURL(`accounts/${routeAccountId}/${billingRedirect}`));
    }
    if (requestedRedirectUrl) {
      return next(
        frontendURL(`accounts/${routeAccountId}/${requestedRedirectUrl}`)
      );
    }
    if (needsShopifyBilling) {
      return next(frontendURL(`accounts/${routeAccountId}/settings/billing`));
    }
    const target = needsOnboarding
      ? onboardingPath(userAccount?.onboarding_step)
      : 'dashboard';
    return next(frontendURL(`accounts/${routeAccountId}/${target}`));
  }

  if (needsShopifyBilling && to.name !== 'billing_settings_index') {
    return next(frontendURL(`accounts/${routeAccountId}/settings/billing`));
  }

  if (needsOnboarding && !isOnOnboardingView(to)) {
    return next(
      frontendURL(
        `accounts/${routeAccountId}/${onboardingPath(userAccount?.onboarding_step)}`
      )
    );
  }
  if (!needsOnboarding && isOnOnboardingView(to)) {
    return next(frontendURL(`accounts/${routeAccountId}/dashboard`));
  }

  const nextRoute = validateLoggedInRoutes(to, store.getters.getCurrentUser);
  return nextRoute ? next(frontendURL(nextRoute)) : next();
};

export const initalizeRouter = () => {
  const userAuthentication = store.dispatch('setUser');

  router.beforeEach(async (to, _from, next) => {
    AnalyticsHelper.page(to.name || '', {
      path: to.path,
      name: to.name,
    });

    await userAuthentication;
    await validateAuthenticateRoutePermission(to, next, store);
  });
};

export default router;
