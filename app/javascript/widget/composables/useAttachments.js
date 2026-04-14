import { computed } from 'vue';
import { useStore } from 'vuex';

export function useAttachments() {
  const store = useStore();

  const shouldShowFilePicker = computed(
    () => store.getters['appConfig/getShouldShowFilePicker']
  );

  const shouldShowEmojiPicker = computed(
    () => store.getters['appConfig/getShouldShowEmojiPicker']
  );

  const hasAttachmentsEnabled = computed(() => {
    const channelConfig = window.chatwootWebChannel;
    return channelConfig?.enabledFeatures?.includes('attachments') || false;
  });

  const hasEmojiPickerEnabled = computed(() => {
    const channelConfig = window.chatwootWebChannel;
    return channelConfig?.enabledFeatures?.includes('emoji_picker') || false;
  });

  const canHandleAttachments = computed(() => {
    // If enableFileUpload was explicitly set via SDK, prioritize that
    if (shouldShowFilePicker.value !== undefined) {
      return shouldShowFilePicker.value;
    }

    // Otherwise, fall back to inbox settings only
    return hasAttachmentsEnabled.value;
  });

  return {
    shouldShowFilePicker,
    shouldShowEmojiPicker,
    hasAttachmentsEnabled,
    hasEmojiPickerEnabled,
    canHandleAttachments,
  };
}
