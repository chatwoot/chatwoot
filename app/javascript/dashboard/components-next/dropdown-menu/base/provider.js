import { inject, provide } from 'vue';

const DropdownControl = Symbol('DropdownControl');
const DropdownTeleport = Symbol('DropdownTeleport');

export function useDropdownContext() {
  const context = inject(DropdownControl, null);

  if (context === null) {
    throw new Error(
      `Component is missing a parent <DropdownContainer /> component.`
    );
  }

  return context;
}

export function provideDropdownContext(context) {
  provide(DropdownControl, context);
}

/**
 * Opts every dropdown below this component into rendering its menu on <body>, for subtrees
 * living inside a scrolling or clipping ancestor that would otherwise cut the menu off.
 */
export function provideDropdownTeleport() {
  provide(DropdownTeleport, true);
}

export function useDropdownTeleport() {
  return inject(DropdownTeleport, false);
}
