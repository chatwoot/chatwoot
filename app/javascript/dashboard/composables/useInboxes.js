import { ref, onMounted } from 'vue';
import InboxesAPI from 'dashboard/api/inboxes';
import * as Sentry from '@sentry/vue';

export function useInboxes() {
  const inboxes = ref([]);
  const loading = ref(false);

  const fetchInboxes = async () => {
    try {
      loading.value = true;
      const response = await InboxesAPI.get();
      inboxes.value = response.data.payload;
    } catch (error) {
      Sentry.captureException(error);
    } finally {
      loading.value = false;
    }
  };

  onMounted(fetchInboxes);

  return { inboxes, loading, fetchInboxes };
}
