import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store.js';

export function useAssistantSwitcher() {
  const route = useRoute();
  const router = useRouter();
  const store = useStore();

  const fetchDataForRoute = async (routeName, assistantId) => {
    const dataFetchMap = {
      captain_assistants_documents_index: async () => {
        await store.dispatch('captainDocuments/get', { assistantId });
      },
      captain_assistants_scenarios_index: async () => {
        await store.dispatch('captainScenarios/get', { assistantId });
      },
      captain_assistants_playground_index: () => {
        // Playground doesn't need pre-fetching, it loads on interaction
      },
      captain_assistants_inboxes_index: async () => {
        await store.dispatch('captainInboxes/get', { assistantId });
      },
      captain_assistants_settings_index: async () => {
        await store.dispatch('captainAssistants/show', assistantId);
      },
    };

    const fetchFn = dataFetchMap[routeName];
    if (fetchFn) {
      await fetchFn();
    }
  };

  const switchAssistant = async assistant => {
    const targetRouteName = route.name || 'captain_assistants_overview_index';

    await fetchDataForRoute(targetRouteName, assistant.id);

    await router.push({
      name: targetRouteName,
      params: {
        accountId: route.params.accountId,
        assistantId: assistant.id,
      },
    });
  };

  return { switchAssistant };
}
