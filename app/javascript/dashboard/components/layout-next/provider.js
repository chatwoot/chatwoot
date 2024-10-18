import { inject, provide } from 'vue';
import { useRouter } from 'vue-router';

const SidebarControl = Symbol('SidebarControl');

export function useSidebarContext() {
  const context = inject(SidebarControl, null);
  if (context === null) {
    throw new Error(`Component is missing a parent <Sidebar /> component.`);
  }

  const router = useRouter();

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

  return {
    ...context,
    resolvePath,
    resolvePermissions,
    resolveFeatureFlag,
  };
}

export function provideSidebarContext(context) {
  provide(SidebarControl, context);
}
