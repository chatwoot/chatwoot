import { ref, onMounted, computed } from 'vue';
import LlmAPI from 'dashboard/api/saas/llm';

const NON_CHAT_MODEL_IDS = new Set([
  'whisper-1',
  'text-embedding-3-small',
  'tts-1',
  'tts-1-hd',
  'gpt-4o-realtime-preview',
  'gpt-realtime',
  'gpt-realtime-mini',
  'eleven_turbo_v2_5',
  'eleven_multilingual_v2',
]);

export function useAvailableModels() {
  const allModels = ref([]);
  const isLoadingModels = ref(false);

  const chatModels = computed(() =>
    allModels.value.filter(m => !NON_CHAT_MODEL_IDS.has(m.id))
  );

  const modelOptions = computed(() =>
    chatModels.value.map(m => ({
      value: m.id,
      label: m.coming_soon ? `${m.display_name} (Coming soon)` : m.display_name,
      disabled: m.coming_soon,
    }))
  );

  const modelGroupOptions = computed(() => {
    const grouped = {};
    chatModels.value.forEach(m => {
      const provider = m.provider || 'other';
      if (!grouped[provider]) grouped[provider] = [];
      grouped[provider].push({
        value: m.id,
        label: m.coming_soon
          ? `${m.display_name} (Coming soon)`
          : m.display_name,
        disabled: m.coming_soon,
      });
    });
    return Object.entries(grouped).map(([provider, options]) => ({
      label: provider.charAt(0).toUpperCase() + provider.slice(1),
      options,
    }));
  });

  const fetchModels = async () => {
    isLoadingModels.value = true;
    try {
      const { data } = await LlmAPI.getModels();
      allModels.value = data.models || [];
    } catch {
      allModels.value = [];
    } finally {
      isLoadingModels.value = false;
    }
  };

  onMounted(fetchModels);

  return {
    allModels,
    chatModels,
    modelOptions,
    modelGroupOptions,
    isLoadingModels,
    fetchModels,
  };
}
