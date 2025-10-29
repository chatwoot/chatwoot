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

  const { shouldShow } = usePolicy();

  const resolvePath = to => {
    if (!to) return '/';
    try {
      const resolved = router.resolve(to);
      return resolved?.path || '/';
    } catch (error) {
      return '/';
    }
  };

  const resolvePermissions = to => {
    if (!to) return [];
    try {
      const resolved = router.resolve(to);
      return resolved?.meta?.permissions ?? [];
    } catch (error) {
      return [];
    }
  };

  const resolveFeatureFlag = to => {
    if (!to) return '';
    try {
      const resolved = router.resolve(to);
      return resolved?.meta?.featureFlag || '';
    } catch (error) {
      return '';
    }
  };

  const resolveInstallationType = to => {
    if (!to) return [];
    try {
      const resolved = router.resolve(to);
      return resolved?.meta?.installationTypes || [];
    } catch (error) {
      return [];
    }
  };

  const isAllowed = to => {
    if (!to) return false;

    try {
      const permissions = resolvePermissions(to);
      const featureFlag = resolveFeatureFlag(to);
      const installationType = resolveInstallationType(to);

      return shouldShow(featureFlag, permissions, installationType);
    } catch (error) {
      // eslint-disable-next-line no-console
      console.warn('Error checking permissions for route:', to, error);
      return false;
    }
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
