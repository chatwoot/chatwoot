import { ref, onMounted } from 'vue';
import payzahSettingsAPI from 'dashboard/api/payzahSettings';
import tapSettingsAPI from 'dashboard/api/tapSettings';

export function usePaymentProviders() {
  const providers = ref([]);
  const isLoading = ref(true);
  const defaultProvider = ref(null);

  const loadProviders = async () => {
    isLoading.value = true;
    const enabledProviders = [];

    try {
      const payzahResponse = await payzahSettingsAPI.get();
      if (payzahResponse.data?.enabled) {
        enabledProviders.push({
          id: 'payzah',
          name: 'Payzah',
        });
      }
    } catch {
      // Payzah not configured
    }

    try {
      const tapResponse = await tapSettingsAPI.get();
      if (tapResponse.data?.enabled) {
        enabledProviders.push({
          id: 'tap',
          name: 'Tap',
        });
      }
    } catch {
      // Tap not configured
    }

    providers.value = enabledProviders;

    // Set default provider (first enabled one)
    if (enabledProviders.length > 0) {
      defaultProvider.value = enabledProviders[0].id;
    }

    isLoading.value = false;
  };

  const hasMultipleProviders = () => providers.value.length > 1;
  const hasAnyProvider = () => providers.value.length > 0;

  onMounted(() => {
    loadProviders();
  });

  return {
    providers,
    isLoading,
    defaultProvider,
    hasMultipleProviders,
    hasAnyProvider,
    loadProviders,
  };
}
