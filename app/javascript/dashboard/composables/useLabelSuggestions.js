import { computed, onMounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';

export function useLabelSuggestions() {
  const store = useStore();
  const appIntegrations = useMapGetter('integrations/getAppIntegrations');

  const aiIntegration = computed(
    () =>
      appIntegrations.value.find(
        integration => integration.id === 'openai' && !!integration.hooks.length
      )?.hooks[0]
  );

  const isLabelSuggestionFeatureEnabled = computed(() => {
    if (aiIntegration.value) {
      const { settings = {} } = aiIntegration.value || {};
      return !!settings.label_suggestion;
    }
    return false;
  });

  const fetchIntegrationsIfRequired = async () => {
    if (!appIntegrations.value.length) {
      await store.dispatch('integrations/get');
    }
  };

  onMounted(() => {
    fetchIntegrationsIfRequired();
  });

  return {
    isLabelSuggestionFeatureEnabled,
  };
}
