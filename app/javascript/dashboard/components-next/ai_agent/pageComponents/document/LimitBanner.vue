<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAIAgent } from 'dashboard/composables/useAIAgent';
import Banner from 'dashboard/components-next/banner/Banner.vue';

const router = useRouter();
const { documentLimits, fetchLimits } = useAIAgent();

const shouldShowBanner = computed(() => {
  if (!documentLimits.value) return false;

  const { usage, limit } = documentLimits.value;
  return usage >= limit;
});

const openBillingSettings = () => {
  router.push({ name: 'billing_settings_index' });
};

fetchLimits();
</script>

<template>
  <Banner
    v-if="shouldShowBanner"
    color="warning"
    :action-label="$t('AI_AGENT.BANNER.UPGRADE_PLAN')"
    @action="openBillingSettings"
  >
    {{ $t('AI_AGENT.BANNER.DOCUMENTS') }}
  </Banner>
</template>
