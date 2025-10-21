import store from '../store';

/**
 * Route guard to check if user has required subscription feature
 * Redirects to subscription paywall if access is denied
 * Super admins always have access to all features
 *
 * @param {string} featureName - The feature to check (e.g., 'voice_agents', 'reports', 'campaigns')
 * @returns {Function} - Vue Router navigation guard
 */
export function requiresSubscriptionFeature(featureName) {
  return (to, from, next) => {
    const accountId = to.params.accountId;

    if (!accountId) {
      next();
      return;
    }

    // Super admins bypass all subscription checks
    const currentUser = store.getters.getCurrentUser;
    if (currentUser?.type === 'SuperAdmin') {
      next();
      return;
    }

    // Check if account has the required subscription feature
    const hasFeature = store.getters['accounts/hasSubscriptionFeature'](
      accountId,
      featureName
    );

    if (hasFeature) {
      next();
    } else {
      // Redirect to subscription paywall with feature info
      next({
        name: 'subscription_paywall',
        params: { accountId },
        query: { feature: featureName, from: to.path },
      });
    }
  };
}

/**
 * Check multiple features (user needs at least one)
 * Super admins always have access to all features
 * @param {Array<string>} features - Array of feature names
 * @returns {Function} - Vue Router navigation guard
 */
export function requiresAnySubscriptionFeature(features) {
  return (to, from, next) => {
    const accountId = to.params.accountId;

    if (!accountId) {
      next();
      return;
    }

    // Super admins bypass all subscription checks
    const currentUser = store.getters.getCurrentUser;
    if (currentUser?.type === 'SuperAdmin') {
      next();
      return;
    }

    // Check if account has at least one of the required features
    const hasAnyFeature = features.some(feature =>
      store.getters['accounts/hasSubscriptionFeature'](accountId, feature)
    );

    if (hasAnyFeature) {
      next();
    } else {
      // Redirect to subscription paywall with first feature in list
      next({
        name: 'subscription_paywall',
        params: { accountId },
        query: { feature: features[0], from: to.path },
      });
    }
  };
}
