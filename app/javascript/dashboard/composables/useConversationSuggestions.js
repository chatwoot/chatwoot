import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ConversationAPI from 'dashboard/api/conversations';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

/**
 * Captain Classifier suggestions for the current conversation, cached until a
 * new message arrives. Keyed on the last non-activity message because label and
 * priority changes create activity messages, which would bust a last_activity_at key.
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

  const isActive = computed(() => !!activeKey.value);
  const suggestions = computed(() => results.value[activeKey.value]);
  const isLoading = computed(
    () => isActive.value && suggestions.value === undefined
  );

  const dismiss = () => {
    activeKey.value = null;
  };

  watch(() => conversation.value?.id, dismiss);

  const toggleSuggestions = async () => {
    if (isActive.value && !isLoading.value) {
      dismiss();
      return;
    }

    const { id, last_non_activity_message: lastMessage } = conversation.value;
    const key = `${id}:${lastMessage?.id}`;
    activeKey.value = key;
    if (key in results.value) return;

    results.value[key] = undefined;
    try {
      const { data } = await ConversationAPI.getSuggestions(id, type);
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
