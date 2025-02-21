import { inject, provide } from 'vue';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { useRouter } from 'vue-router';

const SidebarControl = Symbol('SidebarControl');

export function useSidebarContext() {
  const context = inject(SidebarControl, null);
  if (context === null) {
    throw new Error(`Component is missing a parent <Sidebar /> component.`);
  }

  const router = useRouter();

  const {
    checkFeatureAllowed,
    checkPermissions,
    checkInstallationType,
    isPremiumFeature,
  } = usePolicy();

  const resolvePath = to => {
    if (to) return router.resolve(to)?.path || '/';
    return '/';
  };

  const resolvePermissions = to => {
    if (to) return router.resolve(to)?.meta?.permissions ?? [];
    return [];
  };

  const resolveFeatureFlag = to => {
    if (to) return router.resolve(to)?.meta?.featureFlag || '';
    return '';
  };

  const resolveInstallationType = to => {
    if (to) return router.resolve(to)?.meta?.installationTypes || [];
    return [];
  };

  const isAllowed = to => {
    const permissions = resolvePermissions(to);
    const featureFlag = resolveFeatureFlag(to);
    const isPremiumWithPaywall = isPremiumFeature(featureFlag);
    const installationType = resolveInstallationType(to);

    return (
      checkPermissions(permissions) &&
      (checkFeatureAllowed(featureFlag) || isPremiumWithPaywall) &&
      checkInstallationType(installationType)
    );
  };

  return {
    ...context,
    resolvePath,
    resolvePermissions,
    resolveFeatureFlag,
    isAllowed,
  };
}

export function provideSidebarContext(context) {
  provide(SidebarControl, context);
}
