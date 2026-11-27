<script setup>
import { computed, watchEffect } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const router = useRouter();
const { currentAccount } = useAccount();
const { shouldShow, shouldShowPaywall } = usePolicy();
const assistantFlags = useMapGetter('captainAssistants/getUIFlags');

const isLoading = computed(
  () => !currentAccount.value.id || assistantFlags.value.fetchingList
);

const isCopilotAvailable = computed(() =>
  shouldShow(
    route.meta.featureFlag,
    route.meta.permissions,
    route.meta.installationTypes
  )
);

watchEffect(() => {
  if (!isLoading.value && !isCopilotAvailable.value) {
    router.replace({ name: 'home' });
  }
});
</script>

<template>
  <section class="flex items-center justify-center flex-1 min-w-0 h-full">
    <Spinner v-if="isLoading" class="text-n-slate-10" />
    <CaptainPaywall v-else-if="shouldShowPaywall(FEATURE_FLAGS.CAPTAIN)" />
  </section>
</template>
