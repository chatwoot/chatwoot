<script setup>
import { computed, toRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVoucherCalculator } from './composables/useVoucherCalculator';

const props = defineProps({
  profile: { type: Object, required: true },
});

const { t } = useI18n();
const profileRef = toRef(props, 'profile');

const {
  CONTENT_ELEMENTS,
  includeReel,
  includeCarousel,
  includeStories,
  rightsLevel,
  contentMultiplier,
  rightsMultiplier,
  voucherValue,
} = useVoucherCalculator(profileRef);

const isEnriched = computed(() => props.profile.fqs_score != null);

const toggles = computed(() => [
  {
    key: 'reel',
    label: t('INFLUENCER.VOUCHER.REEL'),
    weight: CONTENT_ELEMENTS.reel.weight,
    model: includeReel,
  },
  {
    key: 'carousel',
    label: t('INFLUENCER.VOUCHER.CAROUSEL'),
    weight: CONTENT_ELEMENTS.carousel.weight,
    model: includeCarousel,
  },
  {
    key: 'stories',
    label: t('INFLUENCER.VOUCHER.STORIES'),
    weight: CONTENT_ELEMENTS.stories.weight,
    model: includeStories,
  },
]);

function formatVoucher(value) {
  if (value == null) return '-';
  return Math.round(value).toLocaleString('pl-PL');
}
</script>

<!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
<template>
  <div class="rounded-lg border border-n-weak p-4">
    <h4 class="mb-3 text-sm font-semibold text-n-slate-12">
      {{ t('INFLUENCER.VOUCHER.TITLE') }}
    </h4>

    <template v-if="isEnriched">
      <!-- Content Package toggles -->
      <p class="mb-1.5 text-xs text-n-slate-11">
        {{ t('INFLUENCER.VOUCHER.CONTENT_PACKAGE') }}
      </p>
      <div class="mb-3 flex flex-wrap gap-1.5">
        <button
          v-for="toggle in toggles"
          :key="toggle.key"
          class="rounded-full px-3 py-1 text-xs font-medium transition-colors"
          :class="
            toggle.model.value
              ? 'bg-n-brand text-white'
              : 'bg-n-slate-3 text-n-slate-11'
          "
          @click="toggle.model.value = !toggle.model.value"
        >
          {{ toggle.label }}
          <span class="opacity-70">&times;{{ toggle.weight }}</span>
        </button>
      </div>

      <!-- Rights level -->
      <p class="mb-1.5 text-xs text-n-slate-11">
        {{ t('INFLUENCER.VOUCHER.RIGHTS') }}
      </p>
      <div
        class="mb-4 inline-flex overflow-hidden rounded-lg border border-n-weak"
      >
        <button
          class="px-3 py-1 text-xs font-medium transition-colors"
          :class="
            rightsLevel === 'standard'
              ? 'bg-n-brand text-white'
              : 'bg-n-solid-1 text-n-slate-11 hover:bg-n-background'
          "
          @click="rightsLevel = 'standard'"
        >
          {{ t('INFLUENCER.VOUCHER.STANDARD') }}
          <span class="opacity-70">1.0&times;</span>
        </button>
        <button
          class="px-3 py-1 text-xs font-medium transition-colors"
          :class="
            rightsLevel === 'extended'
              ? 'bg-n-brand text-white'
              : 'bg-n-solid-1 text-n-slate-11 hover:bg-n-background'
          "
          @click="rightsLevel = 'extended'"
        >
          {{ t('INFLUENCER.VOUCHER.EXTENDED') }}
          <span class="opacity-70">1.5&times;</span>
        </button>
      </div>

      <!-- Result -->
      <div class="rounded-lg bg-n-background p-3">
        <p class="text-xs text-n-slate-11">
          {{ t('INFLUENCER.VOUCHER.ESTIMATED_VALUE') }}
        </p>
        <p class="text-2xl font-bold text-n-slate-12">
          &asymp; {{ formatVoucher(voucherValue) }} EUR
        </p>
        <p class="mt-1 font-mono text-[10px] text-n-slate-10">
          {{
            t('INFLUENCER.VOUCHER.FORMULA_HINT', {
              content: contentMultiplier.toFixed(1),
              rights: rightsMultiplier.toFixed(1),
            })
          }}
        </p>
      </div>
    </template>

    <!-- Fallback for non-enriched -->
    <div v-else class="rounded-lg bg-n-blue/10 p-3">
      <p class="text-xs text-n-blue-11">
        {{ t('INFLUENCER.VOUCHER.ENRICH_HINT') }}
      </p>
    </div>
  </div>
</template>
