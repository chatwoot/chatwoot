import { computed, unref } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';
import {
  getUserPermissions,
  hasPermissions,
} from 'dashboard/helper/permissionsHelper';
import { PREMIUM_FEATURES } from 'dashboard/featureFlags';

import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';

export function usePolicy() {
  const user = useMapGetter('getCurrentUser');
  const isFeatureEnabled = useMapGetter('accounts/isFeatureEnabledonAccount');
  const isOnChatwootCloud = useMapGetter('globalConfig/isOnChatwootCloud');
  const isACustomBrandedInstance = useMapGetter(
    'globalConfig/isACustomBrandedInstance'
  );

  const { isEnterprise, enterprisePlanName } = useConfig();
  const { accountId } = useAccount();

  const getUserPermissionsForAccount = () => {
    return getUserPermissions(user.value, accountId.value);
  };

  const isFeatureFlagEnabled = featureFlag => {
    if (!featureFlag) return true;
    return isFeatureEnabled.value(accountId.value, featureFlag);
  };

  const checkPermissions = requiredPermissions => {
    if (!requiredPermissions || !requiredPermissions.length) return true;
    const userPermissions = getUserPermissionsForAccount();
    return hasPermissions(requiredPermissions, userPermissions);
  };

  const checkInstallationType = config => {
    if (Array.isArray(config) && config.length > 0) {
      const installationCheck = {
        [INSTALLATION_TYPES.ENTERPRISE]: isEnterprise,
        [INSTALLATION_TYPES.CLOUD]: isOnChatwootCloud.value,
        [INSTALLATION_TYPES.COMMUNITY]: true,
      };

      return config.some(type => installationCheck[type]);
    }

    return true;
  };

  const isPremiumFeature = featureFlag => {
    if (!featureFlag) return true;
    return PREMIUM_FEATURES.includes(featureFlag);
  };

  const hasPremiumEnterprise = computed(() => {
    if (isEnterprise) return enterprisePlanName !== 'community';

    return true;
  });

  const shouldShow = (featureFlag, permissions, installationTypes) => {
    const flag = unref(featureFlag);
    const perms = unref(permissions);
    const installation = unref(installationTypes);

    // if the user does not have permissions or installation type is not supported
    // return false;
    // This supersedes everything
    if (!checkPermissions(perms)) return false;
    if (!checkInstallationType(installation)) return false;

    if (isACustomBrandedInstance.value) {
      // if this is a custom branded instance, we just use the feature flag as a reference
      return isFeatureFlagEnabled(flag);
    }

    // if on cloud, we should if the feature is allowed
    // or if the feature is a premium one like SLA to show a paywall
    // the paywall should be managed by the individual component
    if (isOnChatwootCloud.value) {
      return isFeatureFlagEnabled(flag) || isPremiumFeature(flag);
    }

    if (isEnterprise) {
      // in enterprise, if the feature is premium but they don't have an enterprise plan
      // we should it anyway this is to show upsells on enterprise regardless of the feature flag
      // Feature flag is only honored if they have a premium plan
      //
      // In case they have a premium plan, the check on feature flag alone is enough
      // because the second condition will always be false
      // That means once subscribed, the feature can be disabled by the admin
      //
      // the paywall should be managed by the individual component
      return (
        isFeatureFlagEnabled(flag) ||
        (isPremiumFeature(flag) && !hasPremiumEnterprise.value)
      );
    }

    // default to true
    return true;
  };

  const shouldShowPaywall = featureFlag => {
    const flag = unref(featureFlag);
    if (!flag) return false;

    if (isACustomBrandedInstance.value) {
      // custom branded instances never show paywall
      return false;
    }

    if (isPremiumFeature(flag)) {
      if (isOnChatwootCloud.value) {
        return !isFeatureFlagEnabled(flag);
      }

      if (isEnterprise) {
        return !hasPremiumEnterprise.value;
      }
    }

    return false;
  };

  return {
    checkPermissions,
    shouldShowPaywall,
    shouldShow,
  };
}
