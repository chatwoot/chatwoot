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
    if (to) return router.resolve(to)?.path || '/';
    return '/';
  };

  // Helper to find route definition by name without resolving
  const findRouteByName = name => {
    const routes = router.getRoutes();
    return routes.find(route => route.name === name);
  };

  const resolvePermissions = to => {
    if (!to) return [];

    // If navigationPath param exists, get the target route definition
    if (to.params?.navigationPath) {
      const targetRoute = findRouteByName(to.params.navigationPath);
      return targetRoute?.meta?.permissions ?? [];
    }

    return router.resolve(to)?.meta?.permissions ?? [];
  };

  const resolveFeatureFlag = to => {
    if (!to) return '';

    // If navigationPath param exists, get the target route definition
    if (to.params?.navigationPath) {
      const targetRoute = findRouteByName(to.params.navigationPath);
      return targetRoute?.meta?.featureFlag || '';
    }

    return router.resolve(to)?.meta?.featureFlag || '';
  };

  const resolveInstallationType = to => {
    if (!to) return [];

    // If navigationPath param exists, get the target route definition
    if (to.params?.navigationPath) {
      const targetRoute = findRouteByName(to.params.navigationPath);
      return targetRoute?.meta?.installationTypes || [];
    }

    return router.resolve(to)?.meta?.installationTypes || [];
  };

  const isAllowed = to => {
    const permissions = resolvePermissions(to);
    const featureFlag = resolveFeatureFlag(to);
    const installationType = resolveInstallationType(to);

    return shouldShow(featureFlag, permissions, installationType);
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
