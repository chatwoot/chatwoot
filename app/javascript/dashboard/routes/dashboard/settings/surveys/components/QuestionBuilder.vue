<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Switch from 'next/switch/Switch.vue';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const questions = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value),
});

const questionTypeOptions = computed(() => [
  { label: t('SURVEYS.QUESTION_TYPES.OPEN_ENDED'), value: 'open_ended' },
  {
    label: t('SURVEYS.QUESTION_TYPES.MULTIPLE_CHOICE'),
    value: 'multiple_choice',
  },
]);

const inputTypeOptions = computed(() => [
  { label: t('SURVEYS.INPUT_TYPES.TEXT'), value: 'text' },
  { label: t('SURVEYS.INPUT_TYPES.NUMBER'), value: 'number' },
]);

const addQuestion = () => {
  const newQuestions = [
    ...questions.value,
    {
      question_text: '',
      question_type: 'open_ended',
      input_type: 'text',
      required: false,
      position: questions.value.length,
      options: [],
      markedForDeletion: false,
    },
  ];
  questions.value = newQuestions;
};

const removeQuestion = index => {
  const newQuestions = [...questions.value];
  if (newQuestions[index].id) {
    newQuestions[index].markedForDeletion = true;
  } else {
    newQuestions.splice(index, 1);
  }
  questions.value = newQuestions;
};

const addOption = questionIndex => {
  const newQuestions = [...questions.value];
  if (!newQuestions[questionIndex].options) {
    newQuestions[questionIndex].options = [];
  }
  newQuestions[questionIndex].options.push({
    option_text: '',
    position: newQuestions[questionIndex].options.length,
    markedForDeletion: false,
  });
  questions.value = newQuestions;
};

const removeOption = (questionIndex, optionIndex) => {
  const newQuestions = [...questions.value];
  const option = newQuestions[questionIndex].options[optionIndex];
  if (option.id) {
    option.markedForDeletion = true;
  } else {
    newQuestions[questionIndex].options.splice(optionIndex, 1);
  }
  questions.value = newQuestions;
};

const onQuestionTypeChange = (questionIndex, newType) => {
  const newQuestions = [...questions.value];
  newQuestions[questionIndex].question_type = newType;
  if (
    newType === 'multiple_choice' &&
    !newQuestions[questionIndex].options?.length
  ) {
    newQuestions[questionIndex].options = [
      { option_text: '', position: 0, markedForDeletion: false },
      { option_text: '', position: 1, markedForDeletion: false },
    ];
  }
  questions.value = newQuestions;
};

const visibleQuestions = computed(() =>
  questions.value.filter(q => !q.markedForDeletion)
);
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center justify-between">
      <label class="text-sm font-medium text-n-slate-12">
        {{ $t('SURVEYS.QUESTIONS.HEADER') }}
      </label>
      <NextButton
        type="button"
        icon="i-lucide-plus"
        :label="$t('SURVEYS.QUESTIONS.ADD.TITLE')"
        ghost
        blue
        xs
        @click="addQuestion"
      />
    </div>

    <div
      v-if="visibleQuestions.length === 0"
      class="text-sm text-n-slate-11 text-center py-4"
    >
      {{ $t('SURVEYS.QUESTIONS.404') }}
    </div>

    <div
      v-for="(question, qIndex) in questions"
      v-show="!question.markedForDeletion"
      :key="qIndex"
      class="p-4 border rounded-lg border-n-weak bg-n-slate-1"
    >
      <div class="flex items-start gap-2 mb-3">
        <span class="text-sm font-semibold text-n-slate-12 mt-2">
          {{ qIndex + 1 }}.
        </span>
        <div class="flex-1 flex flex-col gap-3">
          <TextArea
            :id="`question-text-${qIndex}`"
            v-model="question.question_text"
            :placeholder="
              $t('SURVEYS.QUESTIONS.FORM.QUESTION_TEXT.PLACEHOLDER')
            "
          />

          <div class="grid grid-cols-2 gap-3">
            <div class="flex flex-col gap-1">
              <label class="text-xs font-medium text-n-slate-11">
                {{ $t('SURVEYS.QUESTIONS.FORM.QUESTION_TYPE.LABEL') }}
              </label>
              <FilterSelect
                v-model="question.question_type"
                :options="questionTypeOptions"
                @update:model-value="
                  newValue => onQuestionTypeChange(qIndex, newValue)
                "
              />
            </div>

            <div
              v-if="question.question_type === 'open_ended'"
              class="flex flex-col gap-1"
            >
              <label class="text-xs font-medium text-n-slate-11">
                {{ $t('SURVEYS.QUESTIONS.FORM.INPUT_TYPE.LABEL') }}
              </label>
              <FilterSelect
                v-model="question.input_type"
                :options="inputTypeOptions"
              />
            </div>
          </div>

          <div
            v-if="question.question_type === 'multiple_choice'"
            class="flex flex-col gap-2"
          >
            <label class="text-xs font-medium text-n-slate-11">
              {{ $t('SURVEYS.QUESTIONS.FORM.OPTIONS.LABEL') }}
            </label>
            <div
              v-for="(option, oIndex) in question.options?.filter(
                opt => !opt.markedForDeletion
              )"
              :key="oIndex"
              class="flex items-center gap-2"
            >
              <Input
                :id="`option-${qIndex}-${oIndex}`"
                v-model="option.option_text"
                :placeholder="
                  $t('SURVEYS.QUESTIONS.FORM.OPTIONS.PLACEHOLDER', {
                    number: oIndex + 1,
                  })
                "
                class="flex-1"
              />
              <NextButton
                v-tooltip.top="
                  $t('SURVEYS.QUESTIONS.FORM.OPTIONS.REMOVE_OPTION')
                "
                type="button"
                icon="i-lucide-trash-2"
                xs
                ruby
                faded
                @click="removeOption(qIndex, oIndex)"
              />
            </div>
            <NextButton
              type="button"
              icon="i-lucide-plus"
              :label="$t('SURVEYS.QUESTIONS.FORM.OPTIONS.ADD_OPTION')"
              ghost
              blue
              xs
              @click="addOption(qIndex)"
            />
          </div>

          <div class="flex items-center justify-between">
            <label class="text-xs font-medium text-n-slate-11">
              {{ $t('SURVEYS.QUESTIONS.FORM.REQUIRED.LABEL') }}
            </label>
            <Switch v-model="question.required" />
          </div>
        </div>

        <NextButton
          v-tooltip.top="$t('SURVEYS.QUESTIONS.DELETE.BUTTON_TEXT')"
          type="button"
          icon="i-lucide-trash-2"
          xs
          ruby
          faded
          @click="removeQuestion(qIndex)"
        />
      </div>
    </div>
  </div>
</template>
