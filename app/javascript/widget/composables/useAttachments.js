import { computed } from 'vue';
import { useStore } from 'vuex';

export function useAttachments() {
  const store = useStore();

  const shouldShowFilePicker = computed(
    () => store.getters['appConfig/getShouldShowFilePicker']
  );

  const hasAttachmentsEnabled = computed(() => {
    const channelConfig = window.chatwootWebChannel;
    return channelConfig?.enabledFeatures?.includes('attachments') || false;
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
    hasAttachmentsEnabled,
    canHandleAttachments,
  };
}
