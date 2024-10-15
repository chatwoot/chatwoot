import { inject, provide } from 'vue';
import { useRouter } from 'vue-router';

const SidebarControl = Symbol('SidebarControl');

export function useSidebarContext() {
  const context = inject(SidebarControl, null);
  if (context === null) {
    throw new Error(`Component is missing a parent <Sidebar /> component.`);
  }

  const router = useRouter();
  const resolvePath = to => router.resolve(to).path;
  const resolvePermissions = to => {
    if (!to) return [];

    return router.resolve(to).meta?.permissions ?? [];
  };
  const resolveFeatureFlag = to => {
    if (!to) return '';

    return router.resolve(to).meta?.featureFlag ?? '';
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
