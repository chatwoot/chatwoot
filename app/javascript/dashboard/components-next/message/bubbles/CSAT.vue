<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import { useI18n } from 'vue-i18n';
import { CSAT_RATINGS } from 'shared/constants/messages';
import { useMessageContext } from '../provider.js';

const { contentAttributes } = useMessageContext();
const { t } = useI18n();

const response = computed(() => {
  return contentAttributes.value?.submittedValues?.csatSurveyResponse ?? {};
});

const isRatingSubmitted = computed(() => {
  return !!response.value.rating;
});

const rating = computed(() => {
  if (isRatingSubmitted.value) {
    return CSAT_RATINGS.find(
      csatOption => csatOption.value === response.value.rating
    );
  }

  return null;
});
</script>

<template>
  <BaseBubble class="px-4 py-3" data-bubble-name="csat">
    <h4>{{ t('CONVERSATION.CSAT_REPLY_MESSAGE') }}</h4>
    <dl v-if="isRatingSubmitted" class="mt-4">
      <dt class="text-n-slate-11 italic">
        {{ t('CONVERSATION.RATING_TITLE') }}
      </dt>
      <dd>{{ t(rating.translationKey) }}</dd>

      <dt v-if="response.feedbackMessage" class="text-n-slate-11 italic mt-2">
        {{ t('CONVERSATION.FEEDBACK_TITLE') }}
      </dt>
      <dd>{{ response.feedbackMessage }}</dd>
    </dl>
  </BaseBubble>
</template>
