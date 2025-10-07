<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ContactsAPI from 'dashboard/api/contacts';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  contactId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();

const surveyAnswers = ref([]);
const isLoading = ref(false);

const fetchSurveyAnswers = async () => {
  if (!props.contactId) return;

  isLoading.value = true;
  try {
    const { data } = await ContactsAPI.getSurveyAnswers(props.contactId);
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
</script>

<template>
  <div class="pl-4">
    <div v-if="isLoading" class="flex items-center justify-center py-4">
      <Spinner />
    </div>
    <div v-else-if="surveyAnswers.length > 0" class="flex flex-col gap-3 py-2">
      <div
        v-for="survey in surveyAnswers"
        :key="survey.survey_id"
        class="flex flex-col gap-2 p-3 border border-n-slate-6 rounded bg-n-slate-1"
      >
        <div class="flex items-start justify-between gap-2">
          <h5 class="text-xs font-semibold text-n-slate-12 m-0">
            {{ survey.survey_name }}
          </h5>
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
        <div class="flex flex-col gap-1.5">
          <div
            v-for="answer in survey.answers.slice(0, 2)"
            :key="answer.id"
            class="flex flex-col gap-0.5"
          >
            <span class="text-xs text-n-slate-11">
              {{ answer.question_text }}
            </span>
            <span class="text-xs text-n-slate-12 font-medium">
              {{
                answer.selected_option
                  ? answer.selected_option.option_text
                  : answer.answer_text
              }}
            </span>
          </div>
          <span
            v-if="survey.answers.length > 2"
            class="text-xs text-n-slate-10 italic"
          >
            {{
              $t('SURVEYS.RESPONSES.MORE_ANSWERS', {
                count: survey.answers.length - 2,
              })
            }}
          </span>
        </div>
      </div>
    </div>
    <p v-else class="py-4 text-xs leading-5 text-center text-n-slate-11 m-0">
      {{ $t('SURVEYS.RESPONSES.EMPTY_STATE') }}
    </p>
  </div>
</template>
