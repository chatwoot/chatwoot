<script setup>
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const { currentAccount } = useAccount();
const { shouldShowPaywall } = usePolicy();
const assistantFlags = useMapGetter('captainAssistants/getUIFlags');

const isLoading = computed(
  () => !currentAccount.value.id || assistantFlags.value.fetchingList
);
</script>

<template>
  <section class="flex items-center justify-center flex-1 min-w-0 h-full">
    <Spinner v-if="isLoading" class="text-n-slate-10" />
    <CaptainPaywall v-else-if="shouldShowPaywall(FEATURE_FLAGS.CAPTAIN)" />
  </section>
</template>
