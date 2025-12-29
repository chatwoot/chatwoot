import { ref } from 'vue';
import { debounce } from '@chatwoot/utils';
import leadFollowUpSequencesAPI from '../api/leadFollowUpSequences';

export function useEligibleConversationsPreview() {
  const loading = ref(false);
  const totalCount = ref(null);
  const conversations = ref([]);
  const error = ref(null);

  const fetchPreview = debounce(async params => {
    if (!params.inbox_id) {
      totalCount.value = null;
      conversations.value = [];
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const response = await leadFollowUpSequencesAPI.previewEligible(params);
      totalCount.value = response.data.total_count;
      conversations.value = response.data.conversations;
    } catch (err) {
      error.value = err;
      totalCount.value = null;
      conversations.value = [];
    } finally {
      loading.value = false;
    }
  }, 1000);

  return {
    loading,
    totalCount,
    conversations,
    error,
    fetchPreview,
  };
}
