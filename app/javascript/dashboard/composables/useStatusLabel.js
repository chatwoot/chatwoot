import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import {
  RESOLVED_LABEL_KEYS,
  normalizeResolvedLabelKey,
  getStatusLabel as getStatusLabelHelper,
  getResolveActionLabel as getResolveActionLabelHelper,
  getMarkAsResolvedLabel as getMarkAsResolvedLabelHelper,
  getResolveConversationPhrase as getResolveConversationPhraseHelper,
  getResolutionCountLabel as getResolutionCountLabelHelper,
} from 'dashboard/helper/statusLabelHelper';

export { RESOLVED_LABEL_KEYS };

/**
 * Account-scoped labels for conversation status.
 * Only `resolved` may use an alternate preset label; API slug stays `resolved`.
 */
export function useStatusLabel() {
  const { t } = useI18n();
  const { currentAccount } = useAccount();

  const resolvedLabelKey = computed(() =>
    normalizeResolvedLabelKey(
      currentAccount.value?.settings?.resolved_label_key
    )
  );

  const getStatusLabel = status =>
    getStatusLabelHelper(t, resolvedLabelKey.value, status);

  const getResolveActionLabel = () =>
    getResolveActionLabelHelper(t, resolvedLabelKey.value);

  const getMarkAsResolvedLabel = () =>
    getMarkAsResolvedLabelHelper(t, resolvedLabelKey.value);

  const getResolveConversationPhrase = () =>
    getResolveConversationPhraseHelper(t, resolvedLabelKey.value);

  const getResolutionCountLabel = () =>
    getResolutionCountLabelHelper(t, resolvedLabelKey.value);

  return {
    resolvedLabelKey,
    getStatusLabel,
    getResolveActionLabel,
    getMarkAsResolvedLabel,
    getResolveConversationPhrase,
    getResolutionCountLabel,
  };
}
