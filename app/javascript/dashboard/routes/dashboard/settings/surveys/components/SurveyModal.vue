<script setup>
import { ref, computed, reactive, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { required, helpers } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Switch from 'next/switch/Switch.vue';
import QuestionBuilder from './QuestionBuilder.vue';

const props = defineProps({
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
  selectedSurvey: {
    type: Object,
    default: () => ({}),
  },
});

const MODAL_TYPES = {
  CREATE: 'create',
  EDIT: 'edit',
};

const store = useStore();
const { t } = useI18n();
const dialogRef = ref(null);
const uiFlags = useMapGetter('surveys/getUIFlags');

const formState = reactive({
  surveyName: '',
  surveyDescription: '',
  surveyActive: true,
  questions: [],
});

const v$ = useVuelidate(
  {
    surveyName: {
      required: helpers.withMessage(
        () => t('SURVEYS.FORM.ERRORS.NAME'),
        required
      ),
    },
  },
  formState
);

const isLoading = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? uiFlags.value.isCreating
    : uiFlags.value.isUpdating
);

const dialogTitle = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? t('SURVEYS.ADD.TITLE')
    : t('SURVEYS.EDIT.TITLE')
);

const confirmButtonLabel = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? t('SURVEYS.FORM.CREATE')
    : t('SURVEYS.FORM.UPDATE')
);

const surveyNameError = computed(() =>
  v$.value.surveyName.$error ? v$.value.surveyName.$errors[0]?.$message : ''
);

const resetForm = () => {
  Object.assign(formState, {
    surveyName: '',
    surveyDescription: '',
    surveyActive: true,
    questions: [],
  });
  v$.value.$reset();
};

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  const surveyData = {
    name: formState.surveyName,
    description: formState.surveyDescription,
    active: formState.surveyActive,
  };

  // Add questions with nested attributes format
  if (formState.questions.length > 0) {
    surveyData.survey_questions_attributes = formState.questions
      .filter(q => {
        // Include if marked for deletion and has ID
        if (q.markedForDeletion && q.id) return true;
        // Exclude empty questions (no text)
        if (!q.question_text?.trim()) return false;
        // Include questions with text
        return true;
      })
      .map((q, index) => {
        const questionData = {
          id: q.id,
          question_text: q.question_text,
          question_type: q.question_type,
          input_type: q.input_type || 'text',
          position: index,
          required: q.required || false,
          markedForDeletion: q.markedForDeletion || false,
        };

        if (q.question_type === 'multiple_choice' && q.options) {
          questionData.survey_question_options_attributes = q.options
            .filter(opt => {
              // Include if marked for deletion and has ID
              if (opt.markedForDeletion && opt.id) return true;
              // Exclude empty options
              if (!opt.option_text?.trim()) return false;
              return true;
            })
            .map((opt, optIndex) => ({
              id: opt.id,
              option_text: opt.option_text,
              position: optIndex,
              markedForDeletion: opt.markedForDeletion || false,
            }));
        }

        return questionData;
      });
  }

  const isCreate = props.type === MODAL_TYPES.CREATE;

  try {
    if (isCreate) {
      await store.dispatch('surveys/create', surveyData);
    } else {
      await store.dispatch('surveys/update', {
        id: props.selectedSurvey.id,
        ...surveyData,
      });
    }

    const alertKey = isCreate
      ? t('SURVEYS.ADD.API.SUCCESS_MESSAGE')
      : t('SURVEYS.EDIT.API.SUCCESS_MESSAGE');
    useAlert(alertKey);

    dialogRef.value.close();
    resetForm();
  } catch (error) {
    const errorKey = isCreate
      ? t('SURVEYS.ADD.API.ERROR_MESSAGE')
      : t('SURVEYS.EDIT.API.ERROR_MESSAGE');
    useAlert(errorKey);
  }
};

const initializeForm = () => {
  if (props.selectedSurvey && Object.keys(props.selectedSurvey).length) {
    const { name, description, active, questions } = props.selectedSurvey;
    formState.surveyName = name || '';
    formState.surveyDescription = description || '';
    formState.surveyActive = active !== undefined ? active : true;
    formState.questions = questions
      ? questions.map(q => ({
          ...q,
          options: q.options || [],
          markedForDeletion: false,
        }))
      : [];
  } else {
    resetForm();
  }
};

const closeModal = () => {
  v$.value?.$reset();
};

const onClickClose = () => {
  closeModal();
  dialogRef.value.close();
};

watch(() => props.selectedSurvey, initializeForm, {
  immediate: true,
  deep: true,
});

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    width="3xl"
    overflow-y-auto
    :title="dialogTitle"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="closeModal"
  >
    <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
      <Input
        id="survey-name"
        v-model="formState.surveyName"
        :label="$t('SURVEYS.FORM.NAME.LABEL')"
        :placeholder="$t('SURVEYS.FORM.NAME.PLACEHOLDER')"
        :message="surveyNameError"
        :message-type="surveyNameError ? 'error' : 'info'"
        @blur="v$.surveyName.$touch()"
      />

      <TextArea
        id="survey-description"
        v-model="formState.surveyDescription"
        :label="$t('SURVEYS.FORM.DESCRIPTION.LABEL')"
        :placeholder="$t('SURVEYS.FORM.DESCRIPTION.PLACEHOLDER')"
      />

      <div class="flex items-center justify-between">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('SURVEYS.FORM.ACTIVE.LABEL') }}
        </label>
        <Switch v-model="formState.surveyActive" />
      </div>

      <QuestionBuilder v-model="formState.questions" />

      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <NextButton
          faded
          slate
          type="reset"
          :label="$t('SURVEYS.FORM.CANCEL')"
          @click="onClickClose()"
        />
        <NextButton
          type="submit"
          data-testid="survey-submit"
          :label="confirmButtonLabel"
          :is-loading="isLoading"
          :disabled="v$.$invalid"
        />
      </div>
    </form>
  </Dialog>
</template>
