<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

const { t } = useI18n();

const searchMeta = useMapGetter('influencerProfiles/getSearchMeta');

const creditsLeft = computed(() => searchMeta.value.creditsLeft);

const nextResetDate = computed(() => {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getDate() > 27 ? now.getMonth() + 1 : now.getMonth();
  const reset = new Date(year, month, 27);
  return reset.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
});

const separator = '·';
</script>

<template>
  <span
    v-show="creditsLeft !== null"
    class="inline-flex items-center gap-1 text-xs text-n-slate-11"
  >
    <span>
      {{ t('INFLUENCER.CREDITS.REMAINING', { count: creditsLeft }) }}
    </span>
    <span class="text-n-slate-10">
      {{ separator }}
      {{ t('INFLUENCER.CREDITS.RESETS', { date: nextResetDate }) }}
    </span>
  </span>
</template>
