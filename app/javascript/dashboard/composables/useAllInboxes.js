import { ref } from 'vue';
import InboxesAPI from 'dashboard/api/inboxes';
import * as Sentry from '@sentry/vue';

export function useAllInboxes() {
  const allInboxes = ref([]);
  const loading = ref(false);

  const fetchAllInboxes = async () => {
    try {
      loading.value = true;
      const response = await InboxesAPI.getAll();
      allInboxes.value = response.data.payload;
    } catch (error) {
      Sentry.captureException(error);
    } finally {
      loading.value = false;
    }
  };

  return { allInboxes, loading, fetchAllInboxes };
}
