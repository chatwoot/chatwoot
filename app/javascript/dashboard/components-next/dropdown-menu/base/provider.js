import { inject, provide } from 'vue';

const DropdownControl = Symbol('DropdownControl');

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
