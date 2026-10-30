import { computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { loadRingingCalls } from 'dashboard/helper/voice';

// Restores the cards of calls ringing as the page loads, for accounts with voice. A failed
// load leaves the card to the call's next update.
export function useRingingCallsOnLoad() {
  const store = useStore();
  const { accountId } = useAccount();

  const isVoiceEnabled = computed(() =>
    store.getters['accounts/isFeatureEnabledonAccount'](
      accountId.value,
      FEATURE_FLAGS.CHANNEL_VOICE
    )
  );

  watch(
    isVoiceEnabled,
    enabled => {
      if (enabled) loadRingingCalls().catch(() => {});
    },
    { immediate: true }
  );
}
