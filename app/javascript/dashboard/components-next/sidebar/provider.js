import { inject, provide, ref, computed } from 'vue';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { useRouter } from 'vue-router';
import { useUISettings } from 'dashboard/composables/useUISettings';

const SidebarControl = Symbol('SidebarControl');

const DEFAULT_WIDTH = 200;
const MIN_WIDTH = 56;
const COLLAPSED_THRESHOLD = 160;
const MAX_WIDTH = 320;

// Shared state for active popover (only one can be open at a time)
const activePopover = ref(null);
let globalCloseTimeout = null;

export function useSidebarResize() {
  const { uiSettings, updateUISettings } = useUISettings();

  const sidebarWidth = ref(uiSettings.value.sidebar_width || DEFAULT_WIDTH);
  const isCollapsed = computed(() => sidebarWidth.value < COLLAPSED_THRESHOLD);

  const setSidebarWidth = width => {
    sidebarWidth.value = Math.max(MIN_WIDTH, Math.min(MAX_WIDTH, width));
  };

  const saveWidth = () => {
    updateUISettings({ sidebar_width: sidebarWidth.value });
  };

  const snapToCollapsed = () => {
    sidebarWidth.value = MIN_WIDTH;
    updateUISettings({ sidebar_width: MIN_WIDTH });
  };

  const snapToExpanded = () => {
    sidebarWidth.value = DEFAULT_WIDTH;
    updateUISettings({ sidebar_width: DEFAULT_WIDTH });
  };

  return {
    sidebarWidth,
    isCollapsed,
    setSidebarWidth,
    saveWidth,
    snapToCollapsed,
    snapToExpanded,
    MIN_WIDTH,
    MAX_WIDTH,
    COLLAPSED_THRESHOLD,
    DEFAULT_WIDTH,
  };
}

export function usePopoverState() {
  const setActivePopover = name => {
    clearTimeout(globalCloseTimeout);
    activePopover.value = name;
  };

  const closeActivePopover = () => {
    activePopover.value = null;
  };

  const scheduleClose = (delay = 150) => {
    clearTimeout(globalCloseTimeout);
    globalCloseTimeout = setTimeout(() => {
      closeActivePopover();
    }, delay);
  };

  const cancelClose = () => {
    clearTimeout(globalCloseTimeout);
  };

  return {
    activePopover,
    setActivePopover,
    closeActivePopover,
    scheduleClose,
    cancelClose,
  };
}

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
