import { inject, provide } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const MessageControl = Symbol('MessageControl');

export function useMessageContext() {
  const context = inject(MessageControl, null);
  if (context === null) {
    throw new Error(`Component is missing a parent <Message /> component.`);
  }

  const currentChatAttachments = useMapGetter('getSelectedChatAttachments');

  return { ...context, currentChatAttachments };
}

export function provideMessageContext(context) {
  provide(MessageControl, context);
}
