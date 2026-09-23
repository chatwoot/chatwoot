import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ConversationAPI from 'dashboard/api/conversations';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { MESSAGE_TYPE } from 'shared/constants/messages';

const CLASSIFIED_MESSAGE_TYPES = [MESSAGE_TYPE.INCOMING, MESSAGE_TYPE.OUTGOING];

/**
 * Captain Classifier suggestions for the current conversation, cached per
 * transcript. The key is the latest public customer or agent message, the same
 * messages the classifier reads, so activity messages from label or priority
 * changes reuse the result while a new message closes stale suggestions.
 * @param {'labels'|'priority'} type
 * @param {import('vue').Ref<Object>} conversation
 */
export function useConversationSuggestions(type, conversation) {
  const { t } = useI18n();
  const { isCloudFeatureEnabled } = useAccount();
  const isEnabled = computed(() =>
    isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_CLASSIFIER)
  );
  const results = ref({});
  const activeKey = ref(null);

  const transcriptKey = computed(() => {
    const { id, messages = [] } = conversation.value || {};
    const lastMessage = messages.findLast(
      message =>
        !message.private &&
        CLASSIFIED_MESSAGE_TYPES.includes(message.message_type)
    );
    return `${id}:${lastMessage?.id}`;
  });

  const isActive = computed(() => !!activeKey.value);
  const suggestions = computed(() => results.value[activeKey.value]);
  const isLoading = computed(
    () => isActive.value && suggestions.value === undefined
  );

  const dismiss = () => {
    activeKey.value = null;
  };

  watch(transcriptKey, dismiss);

  const toggleSuggestions = async () => {
    if (isActive.value && !isLoading.value) {
      dismiss();
      return;
    }

    const key = transcriptKey.value;
    activeKey.value = key;
    if (key in results.value) return;

    results.value[key] = undefined;
    try {
      const { data } = await ConversationAPI.getSuggestions(
        conversation.value.id,
        type
      );
      results.value[key] = data;
    } catch {
      delete results.value[key];
      if (activeKey.value === key) dismiss();
      useAlert(t('CONVERSATION.SUGGESTIONS.ERROR'));
    }
  };

  return {
    isEnabled,
    isActive,
    isLoading,
    suggestions,
    toggleSuggestions,
    dismiss,
  };
}
