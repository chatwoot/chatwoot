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
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';

const props = defineProps({
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
  surveyId: {
    type: Number,
    required: true,
  },
  selectedQuestion: {
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
  questionText: '',
  questionType: 'open_ended',
  inputType: 'text',
  required: false,
  position: 0,
  options: [],
});

const questionTypeOptions = [
  { label: t('SURVEYS.QUESTION_TYPES.OPEN_ENDED'), value: 'open_ended' },
  {
    label: t('SURVEYS.QUESTION_TYPES.MULTIPLE_CHOICE'),
    value: 'multiple_choice',
  },
];

const inputTypeOptions = [
  { label: t('SURVEYS.INPUT_TYPES.TEXT'), value: 'text' },
  { label: t('SURVEYS.INPUT_TYPES.NUMBER'), value: 'number' },
];

const v$ = useVuelidate(
  {
    questionText: {
      required: helpers.withMessage(
        () => t('SURVEYS.QUESTIONS.FORM.ERRORS.QUESTION_TEXT'),
        required
      ),
    },
  },
  formState
);

const isLoading = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? uiFlags.value.isCreatingQuestion
    : uiFlags.value.isUpdatingQuestion
);

const dialogTitle = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? t('SURVEYS.QUESTIONS.ADD.TITLE')
    : t('SURVEYS.QUESTIONS.EDIT.TITLE')
);

const confirmButtonLabel = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? t('SURVEYS.QUESTIONS.FORM.CREATE')
    : t('SURVEYS.QUESTIONS.FORM.UPDATE')
);

const questionTextError = computed(() =>
  v$.value.questionText.$error ? v$.value.questionText.$errors[0]?.$message : ''
);

const isMultipleChoice = computed(
  () => formState.questionType === 'multiple_choice'
);

const canSubmit = computed(() => {
  if (v$.value.$invalid) return false;
  if (
    isMultipleChoice.value &&
    formState.options.filter(opt => opt.option_text.trim()).length < 2
  ) {
    return false;
  }
  return true;
});

const addOption = () => {
  formState.options.push({
    option_text: '',
    position: formState.options.length,
    markedForDeletion: false,
  });
};

const removeOption = index => {
  if (formState.options[index].id) {
    formState.options[index].markedForDeletion = true;
  } else {
    formState.options.splice(index, 1);
  }
};

const resetForm = () => {
  Object.assign(formState, {
    questionText: '',
    questionType: 'open_ended',
    inputType: 'text',
    required: false,
    position: 0,
    options: [],
  });
  v$.value.$reset();
};

const handleSubmit = async () => {
  v$.value.$touch();
  if (!canSubmit.value) return;

  const questionData = {
    question_text: formState.questionText,
    question_type: formState.questionType,
    input_type: formState.inputType,
    required: formState.required,
    position: formState.position,
  };

  if (isMultipleChoice.value) {
    questionData.survey_question_options_attributes = formState.options
      .map((opt, idx) => ({
        id: opt.id,
        option_text: opt.option_text,
        position: idx,
        markedForDeletion: opt.markedForDeletion || false,
      }))
      .filter(opt => opt.option_text.trim() || opt.markedForDeletion);
  }

  const isCreate = props.type === MODAL_TYPES.CREATE;

  try {
    if (isCreate) {
      await store.dispatch('surveys/createQuestion', {
        surveyId: props.surveyId,
        questionData,
      });
    } else {
      await store.dispatch('surveys/updateQuestion', {
        surveyId: props.surveyId,
        questionId: props.selectedQuestion.id,
        questionData,
      });
    }

    const alertKey = isCreate
      ? t('SURVEYS.QUESTIONS.ADD.API.SUCCESS_MESSAGE')
      : t('SURVEYS.QUESTIONS.EDIT.API.SUCCESS_MESSAGE');
    useAlert(alertKey);

    dialogRef.value.close();
    resetForm();
  } catch (error) {
    const errorKey = isCreate
      ? t('SURVEYS.QUESTIONS.ADD.API.ERROR_MESSAGE')
      : t('SURVEYS.QUESTIONS.EDIT.API.ERROR_MESSAGE');
    useAlert(errorKey);
  }
};

const initializeForm = () => {
  if (props.selectedQuestion && Object.keys(props.selectedQuestion).length) {
    const {
      question_text: questionText,
      question_type: questionType,
      input_type: inputType,
      required: isRequired,
      position,
      options,
    } = props.selectedQuestion;

    formState.questionText = questionText || '';
    formState.questionType = questionType || 'open_ended';
    formState.inputType = inputType || 'text';
    formState.required = isRequired || false;
    formState.position = position || 0;
    formState.options = options
      ? options.map(opt => ({ ...opt, markedForDeletion: false }))
      : [];
  } else {
    resetForm();
  }
};

const onQuestionTypeChange = newType => {
  formState.questionType = newType;
  if (newType === 'multiple_choice' && formState.options.length === 0) {
    addOption();
    addOption();
  }
};

const closeModal = () => {
  v$.value?.$reset();
};

const onClickClose = () => {
  closeModal();
  dialogRef.value.close();
};

watch(() => props.selectedQuestion, initializeForm, {
  immediate: true,
  deep: true,
});

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="dialogTitle"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="closeModal"
  >
    <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
      <TextArea
        id="question-text"
        v-model="formState.questionText"
        :label="$t('SURVEYS.QUESTIONS.FORM.QUESTION_TEXT.LABEL')"
        :placeholder="$t('SURVEYS.QUESTIONS.FORM.QUESTION_TEXT.PLACEHOLDER')"
        :message="questionTextError"
        :message-type="questionTextError ? 'error' : 'info'"
        @blur="v$.questionText.$touch()"
      />

      <div class="flex flex-col gap-1">
        <label class="mb-0.5 text-sm font-medium text-n-slate-12">
          {{ $t('SURVEYS.QUESTIONS.FORM.QUESTION_TYPE.LABEL') }}
        </label>
        <FilterSelect
          v-model="formState.questionType"
          :options="questionTypeOptions"
          @update:model-value="onQuestionTypeChange"
        />
      </div>

      <div v-if="!isMultipleChoice" class="flex flex-col gap-1">
        <label class="mb-0.5 text-sm font-medium text-n-slate-12">
          {{ $t('SURVEYS.QUESTIONS.FORM.INPUT_TYPE.LABEL') }}
        </label>
        <FilterSelect
          v-model="formState.inputType"
          :options="inputTypeOptions"
        />
      </div>

      <div v-if="isMultipleChoice" class="flex flex-col gap-2">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('SURVEYS.QUESTIONS.FORM.OPTIONS.LABEL') }}
        </label>
        <div
          v-for="(option, index) in formState.options.filter(
            opt => !opt.markedForDeletion
          )"
          :key="index"
          class="flex items-center gap-2"
        >
          <Input
            :id="`option-${index}`"
            v-model="option.option_text"
            :placeholder="
              $t('SURVEYS.QUESTIONS.FORM.OPTIONS.PLACEHOLDER', {
                number: index + 1,
              })
            "
            class="flex-1"
          />
          <NextButton
            v-tooltip.top="$t('SURVEYS.QUESTIONS.FORM.OPTIONS.REMOVE_OPTION')"
            icon="i-lucide-trash-2"
            xs
            ruby
            faded
            @click="removeOption(index)"
          />
        </div>
        <NextButton
          icon="i-lucide-plus"
          :label="$t('SURVEYS.QUESTIONS.FORM.OPTIONS.ADD_OPTION')"
          ghost
          blue
          @click="addOption"
        />
      </div>

      <div class="flex items-center justify-between">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('SURVEYS.QUESTIONS.FORM.REQUIRED.LABEL') }}
        </label>
        <Switch v-model="formState.required" />
      </div>

      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <NextButton
          faded
          slate
          type="reset"
          :label="$t('SURVEYS.QUESTIONS.FORM.CANCEL')"
          @click="onClickClose()"
        />
        <NextButton
          type="submit"
          data-testid="question-submit"
          :label="confirmButtonLabel"
          :is-loading="isLoading"
          :disabled="!canSubmit"
        />
      </div>
    </form>
  </Dialog>
</template>
