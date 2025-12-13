<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  supportPersonality: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const clockImage =
  '/assets/images/dashboard/year-in-review/fourth-frame-clock.png';
const doubleQuotesImage =
  '/assets/images/dashboard/year-in-review/double-quotes.png';

const formatResponseTime = seconds => {
  if (seconds < 60) {
    return 'less than a minute';
  }
  if (seconds < 3600) {
    const minutes = Math.floor(seconds / 60);
    return minutes === 1 ? '1 minute' : `${minutes} minutes`;
  }
  if (seconds < 86400) {
    const hours = Math.floor(seconds / 3600);
    return hours === 1 ? '1 hour' : `${hours} hours`;
  }
  return 'more than a day';
};

const personality = computed(() => {
  const seconds = props.supportPersonality.avg_response_time_seconds;
  const minutes = seconds / 60;

  if (minutes < 2) {
    return 'Swift Helper';
  }
  if (minutes < 5) {
    return 'Quick Responder';
  }
  if (minutes < 15) {
    return 'Steady Support';
  }
  return 'Thoughtful Advisor';
});

const personalityMessage = computed(() => {
  const seconds = props.supportPersonality.avg_response_time_seconds;
  const time = formatResponseTime(seconds);

  const personalityKeyMap = {
    'Swift Helper': 'SWIFT_HELPER',
    'Quick Responder': 'QUICK_RESPONDER',
    'Steady Support': 'STEADY_SUPPORT',
    'Thoughtful Advisor': 'THOUGHTFUL_ADVISOR',
  };

  const key = personalityKeyMap[personality.value];
  if (!key) return '';

  return t(`YEAR_IN_REVIEW.PERSONALITY.MESSAGES.${key}`, { time });
});
</script>

<template>
  <div class="absolute inset-0 flex items-center justify-center px-32 py-20">
    <div class="flex flex-col gap-9 flex-shrink-0 max-w-4xl">
      <div class="mb-4 md:mb-6">
        <img :src="clockImage" alt="Clock" class="w-auto h-24 md:h-32" />
        <div class="flex items-center justify-start flex-1">
          <div class="text-white flex gap-3 flex-col">
            <div class="text-2xl md:text-4xl font-medium tracking-tight">
              {{ t('YEAR_IN_REVIEW.PERSONALITY.TITLE') }}
            </div>
            <div class="text-6xl md:text-8xl lg:text-9xl tracking-tight">
              {{ personality }}
            </div>
          </div>
        </div>
      </div>

      <div class="flex items-center justify-center gap-3 md:gap-6">
        <img
          :src="doubleQuotesImage"
          alt="Quote"
          class="w-8 h-8 md:w-12 md:h-12 lg:w-16 lg:h-16"
        />
        <p
          class="text-xl md:text-3xl lg:text-4xl font-medium tracking-[-0.2px] text-black-900"
        >
          {{ personalityMessage }}
        </p>
      </div>
    </div>
  </div>
</template>
