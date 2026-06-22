<script setup>
import { computed } from 'vue';

const props = defineProps({
  referral: {
    type: Object,
    required: true,
  },
});

const adData = computed(() => props.referral.adsContextData ?? {});
const thumbnailUrl = computed(() => adData.value.photoUrl ?? '');
const adTitle = computed(() => adData.value.adTitle ?? '');
const hasContent = computed(() => !!(thumbnailUrl.value || adTitle.value));
</script>

<template>
  <div
    v-if="referral.source === 'ADS' && hasContent"
    class="rounded-lg overflow-hidden border border-n-slate-4 bg-n-alpha-1 -mx-1"
  >
    <img
      v-if="thumbnailUrl"
      :src="thumbnailUrl"
      class="w-full object-cover max-h-48 skip-context-menu"
      alt=""
    />
    <div class="px-3 py-2 flex flex-col gap-0.5">
      <span class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
        {{ $t('CONVERSATION.AD_REFERRAL.SPONSORED') }}
      </span>
      <p v-if="adTitle" class="m-0 text-sm font-semibold text-n-slate-12">
        {{ adTitle }}
      </p>
    </div>
  </div>
</template>
