import { inject, provide, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { ATTACHMENT_TYPES } from './constants';

const MessageControl = Symbol('MessageControl');

export function useMessageContext() {
  const context = inject(MessageControl, null);
  if (context === null) {
    throw new Error(`Component is missing a parent <Message /> component.`);
  }

  const currentChatAttachments = useMapGetter('getSelectedChatAttachments');
  const filteredCurrentChatAttachments = computed(() => {
    const attachments = currentChatAttachments.value.filter(attachment =>
      [
        ATTACHMENT_TYPES.IMAGE,
        ATTACHMENT_TYPES.VIDEO,
        ATTACHMENT_TYPES.IG_REEL,
        ATTACHMENT_TYPES.AUDIO,
      ].includes(attachment.file_type)
    );

    return useSnakeCase(attachments);
  });

  return { ...context, filteredCurrentChatAttachments };
}

export function provideMessageContext(context) {
  provide(MessageControl, context);
}
