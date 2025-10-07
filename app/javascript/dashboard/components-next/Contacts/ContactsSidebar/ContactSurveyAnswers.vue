<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import ContactsAPI from 'dashboard/api/contacts';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const { t } = useI18n();
const route = useRoute();

const surveyAnswers = ref([]);
const isLoading = ref(false);

const fetchSurveyAnswers = async () => {
  isLoading.value = true;
  try {
    const { data } = await ContactsAPI.getSurveyAnswers(route.params.contactId);
    surveyAnswers.value = data;
  } catch (error) {
    useAlert(t('SURVEYS.RESPONSES.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  fetchSurveyAnswers();
});

const formatDate = dateString => {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleDateString('es-ES', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
};
</script>

<template>
  <div class="flex flex-col gap-6 py-6 px-6">
    <div
      v-if="isLoading"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <div v-else-if="surveyAnswers.length > 0" class="flex flex-col gap-6">
      <div
        v-for="survey in surveyAnswers"
        :key="survey.survey_id"
        class="flex flex-col gap-4 p-4 border border-n-slate-6 rounded-lg bg-n-slate-2"
      >
        <div class="flex items-start justify-between gap-2">
          <div class="flex flex-col gap-1">
            <h4 class="text-sm font-semibold text-n-slate-12">
              {{ survey.survey_name }}
            </h4>
            <p v-if="survey.survey_description" class="text-xs text-n-slate-11">
              {{ survey.survey_description }}
            </p>
          </div>
          <span
            v-if="survey.is_completed"
            class="inline-flex items-center gap-1 px-1.5 py-0.5 text-xs rounded bg-n-green-2 text-n-green-11"
          >
            <span class="i-ph-check-circle text-n-green-9" />
            {{ $t('SURVEYS.STATUS.COMPLETED') }}
          </span>
          <span
            v-else
            class="inline-flex items-center gap-1 px-1.5 py-0.5 text-xs rounded bg-n-yellow-2 text-n-yellow-11"
          >
            <span class="i-ph-clock text-n-yellow-9" />
            {{ $t('SURVEYS.STATUS.IN_PROGRESS') }}
          </span>
        </div>
        <div class="flex flex-col gap-3">
          <div
            v-for="answer in survey.answers"
            :key="answer.id"
            class="flex flex-col gap-1.5"
          >
            <p class="text-xs font-medium text-n-slate-11">
              {{ answer.question_text }}
            </p>
            <div class="flex items-start gap-2">
              <span
                v-if="answer.question_type === 'open_ended'"
                class="text-sm text-n-slate-12"
              >
                {{ answer.answer_text || '-' }}
              </span>
              <div
                v-else
                class="inline-flex items-center gap-2 px-2 py-1 text-xs rounded bg-n-slate-3 text-n-slate-12"
              >
                <span class="i-ph-check-circle text-n-green-9" />
                {{ answer.selected_option?.option_text || '-' }}
              </div>
            </div>
            <span class="text-xs text-n-slate-10">
              {{ formatDate(answer.created_at) }}
            </span>
          </div>
        </div>
      </div>
    </div>
    <p v-else class="py-6 text-sm leading-6 text-center text-n-slate-11">
      {{ t('CONTACTS_LAYOUT.SIDEBAR.SURVEY_ANSWERS.EMPTY_STATE') }}
    </p>
  </div>
</template>
