import { inject, provide } from 'vue';
const SidebarControl = Symbol('SidebarControl');

export function useSidebarContext() {
  const context = inject(SidebarControl, null);

  if (context === null) {
    throw new Error(`Component is missing a parent <Sidebar /> component.`);
  }

  return context;
}

export function provideSidebarContext(context) {
  provide(SidebarControl, context);
}
