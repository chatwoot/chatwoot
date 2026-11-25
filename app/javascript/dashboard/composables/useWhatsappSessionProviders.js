import { ref, computed } from 'vue';
import WhatsappChannel from 'dashboard/api/channel/whatsappChannel';

/**
 * The WhatsApp session provider catalog, as the server describes it: which providers
 * this account may pick, what each one's setup form asks for, and what it can do once
 * connected.
 *
 * The dashboard renders the picker and the setup form from this instead of carrying a
 * component and a provider name per provider, so adding one is a server-side change.
 *
 * Fetching is left to the caller: the catalog is read once per page, by whoever owns the
 * page, and passed down. A composable that fetched on mount would fetch once per
 * component that happened to need a field name.
 */
export const useWhatsappSessionProviders = () => {
  const providers = ref([]);
  const isFetching = ref(false);

  const fetchProviders = async () => {
    isFetching.value = true;
    try {
      const { data } = await WhatsappChannel.getSessionProviders();
      providers.value = data?.payload ?? [];
    } catch {
      // The catalog is what the picker offers, so a failed fetch offers nothing rather
      // than a provider the server would then refuse. The rest of the WhatsApp providers
      // are static and keep working.
      providers.value = [];
    } finally {
      isFetching.value = false;
    }
  };

  const descriptorFor = key => providers.value.find(p => p.key === key);

  const creatableProviders = computed(() =>
    providers.value.filter(p => p.creatable)
  );

  // Offered but not openable right now, with the server's reason (today only `native`
  // while no connector is running). The picker shows these disabled instead of leaving
  // them out, so an administrator learns why rather than assuming the feature is missing.
  const unavailableProviders = computed(() =>
    providers.value.filter(p => !p.creatable && p.unavailable_reason)
  );

  return {
    providers,
    isFetching,
    fetchProviders,
    descriptorFor,
    creatableProviders,
    unavailableProviders,
  };
};
