import { ref, onMounted } from 'vue';
import hubIntegrationsAPI from 'dashboard/api/hubIntegrations';

const actions = ref([]);
const loaded = ref(false);
const loading = ref(false);

export function useHubIntegrations() {
  const fetchActions = async () => {
    if (loaded.value || loading.value) return;
    loading.value = true;
    try {
      const { data } = await hubIntegrationsAPI.getAvailableActions();
      actions.value = data.actions || [];
    } catch {
      actions.value = [];
    } finally {
      loaded.value = true;
      loading.value = false;
    }
  };

  const hasAction = key => actions.value.some(a => a.key === key);

  const getAction = key => actions.value.find(a => a.key === key);

  onMounted(fetchActions);

  return {
    actions,
    loaded,
    loading,
    hasAction,
    getAction,
    fetchActions,
  };
}
