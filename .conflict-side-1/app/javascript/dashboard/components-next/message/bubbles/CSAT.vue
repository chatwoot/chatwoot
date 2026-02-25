<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import { useI18n } from 'vue-i18n';
import { CSAT_RATINGS, CSAT_DISPLAY_TYPES } from 'shared/constants/messages';
import { useMessageContext } from '../provider.js';

const { contentAttributes, content } = useMessageContext();
const { t } = useI18n();

const response = computed(() => {
  return contentAttributes.value?.submittedValues?.csatSurveyResponse ?? {};
});

const isRatingSubmitted = computed(() => {
  return !!response.value.rating;
});

const displayType = computed(() => {
  return contentAttributes.value?.displayType || CSAT_DISPLAY_TYPES.EMOJI;
});

const isStarRating = computed(() => {
  return displayType.value === CSAT_DISPLAY_TYPES.STAR;
});

const rating = computed(() => {
  if (isRatingSubmitted.value) {
    return CSAT_RATINGS.find(
      csatOption => csatOption.value === response.value.rating
    );
  }

  return null;
});

const starRatingValue = computed(() => {
  return response.value.rating || 0;
});
</script>

<template>
  <BaseBubble class="px-4 py-3" data-bubble-name="csat">
    <h4>{{ content || t('CONVERSATION.CSAT_REPLY_MESSAGE') }}</h4>
    <dl v-if="isRatingSubmitted" class="mt-4">
      <dt class="text-n-slate-11 italic">
        {{ t('CONVERSATION.RATING_TITLE') }}
      </dt>
      <dd v-if="!isStarRating">
        {{ t(rating.translationKey) }}
      </dd>
      <dd v-else class="flex mt-1">
        <span v-for="n in 5" :key="n" class="text-2xl mr-1">
          <i
            :class="[
              n <= starRatingValue
                ? 'i-ri-star-fill text-n-amber-9'
                : 'i-ri-star-line text-n-slate-10',
            ]"
          />
        </span>
      </dd>

      <dt v-if="response.feedbackMessage" class="text-n-slate-11 italic mt-2">
        {{ t('CONVERSATION.FEEDBACK_TITLE') }}
      </dt>
      <dd>{{ response.feedbackMessage }}</dd>
    </dl>
  </BaseBubble>
</template>
