import { inject, provide } from 'vue';

const MessageControl = Symbol('MessageControl');

export function useMessageContext() {
  const context = inject(MessageControl, null);
  if (context === null) {
    throw new Error(`Component is missing a parent <Message /> component.`);
  }

  return { ...context };
}

export function provideMessageContext(context) {
  provide(MessageControl, context);
}
