<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  totalConversations: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();

const cloudImage =
  '/assets/images/dashboard/year-in-review/second-frame-cloud-icon.png';

const formatNumber = num => {
  if (num >= 100000) {
    return '100k+';
  }
  return new Intl.NumberFormat().format(num);
};

const performanceHelperText = computed(() => {
  const count = props.totalConversations;
  if (count <= 50) return t('YEAR_IN_REVIEW.CONVERSATIONS.COMPARISON.0_50');
  if (count <= 100) return t('YEAR_IN_REVIEW.CONVERSATIONS.COMPARISON.50_100');
  if (count <= 500) return t('YEAR_IN_REVIEW.CONVERSATIONS.COMPARISON.100_500');
  if (count <= 2000)
    return t('YEAR_IN_REVIEW.CONVERSATIONS.COMPARISON.500_2000');
  if (count <= 10000)
    return t('YEAR_IN_REVIEW.CONVERSATIONS.COMPARISON.2000_10000');
  return t('YEAR_IN_REVIEW.CONVERSATIONS.COMPARISON.10000_PLUS');
});
</script>

<template>
  <div class="absolute inset-0 flex items-center justify-center px-32 py-20">
    <div
      class="flex flex-col gap-3 flex-shrink-0"
      :class="totalConversations > 100 ? 'max-w-4xl' : 'max-w-3xl'"
    >
      <div class="flex items-center justify-center flex-1">
        <div
          class="flex items-center justify-between gap-6 flex-1"
          :class="totalConversations > 100 ? 'md:gap-16' : 'md:gap-8'"
        >
          <div class="text-white flex gap-3 flex-col">
            <div
              class="text-2xl md:text-4xl lg:text-5xl font-medium tracking-tight"
            >
              {{ t('YEAR_IN_REVIEW.CONVERSATIONS.TITLE') }}
            </div>
            <div class="text-6xl md:text-8xl lg:text-[180px] tracking-tighter">
              {{ formatNumber(totalConversations) }}
            </div>
            <div
              class="text-2xl md:text-4xl lg:text-5xl font-medium tracking-tight -mt-2"
            >
              {{ t('YEAR_IN_REVIEW.CONVERSATIONS.SUBTITLE') }}
            </div>
          </div>

          <img
            :src="cloudImage"
            alt="Cloud"
            class="w-auto h-32 md:h-56 lg:h-80 -mr-2"
          />
        </div>
      </div>

      <div class="flex items-center justify-center gap-3 md:gap-6">
        <!-- eslint-disable-next-line -->
        <span class="text-4xl mt-14 md:text-6xl lg:text-9xl leading-none font-bold text-black-900">
          &ldquo;
        </span>
        <p
          class="text-xl md:text-3xl lg:text-4xl font-medium tracking-[-0.2px] text-black-900"
        >
          {{ performanceHelperText }}
        </p>
      </div>
    </div>
  </div>
</template>
