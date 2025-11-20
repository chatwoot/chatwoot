<script setup>
import { reactive, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';

const props = defineProps({
  contest: {
    type: Object,
    default: () => ({}),
  },
  submitLabel: {
    type: String,
    default: 'CONTESTS.FORM_SUBMIT',
  },
  heading: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['submit', 'cancel']);
const { t } = useI18n();
const headingText = computed(() => props.heading || t('CONTESTS.FORM_HEADING'));
const submitText = computed(
  () => props.submitLabel || t('CONTESTS.FORM_SUBMIT')
);

const defaultForm = {
  name: '',
  trigger_words: [],
  start_date: '',
  end_date: '',
  description: '',
  terms: '',
  questionnaire: [],
};

const form = reactive({ ...defaultForm, ...props.contest });
const errors = reactive({
  name: '',
  trigger_words: '',
  start_date: '',
  end_date: '',
  description: '',
  terms: '',
  questionnaire: [],
});

const ensureQuestionnaireEntry = () => {
  if (!Array.isArray(form.questionnaire)) {
    form.questionnaire = [];
  }
  if (!form.questionnaire.length) {
    form.questionnaire.push({
      question: '',
      description: '',
    });
  }
};

const syncQuestionnaireErrors = () => {
  if (!Array.isArray(errors.questionnaire)) {
    errors.questionnaire = [];
  }
  ensureQuestionnaireEntry();
  while (errors.questionnaire.length < form.questionnaire.length) {
    errors.questionnaire.push('');
  }
  while (errors.questionnaire.length > form.questionnaire.length) {
    errors.questionnaire.pop();
  }
};

ensureQuestionnaireEntry();
syncQuestionnaireErrors();

watch(
  () => props.contest,
  value => {
    Object.assign(form, defaultForm, value);
    ensureQuestionnaireEntry();
    Object.keys(errors).forEach(key => {
      errors[key] = key === 'questionnaire' ? [] : '';
    });
    syncQuestionnaireErrors();
  },
  { deep: true }
);

watch(
  () => form.trigger_words,
  newValue => {
    const incoming = Array.isArray(newValue) ? newValue : [];
    const sanitized = Array.from(
      new Set(incoming.map(word => word?.trim()).filter(Boolean))
    );
    if (
      sanitized.length !== incoming.length ||
      sanitized.some((value, index) => value !== incoming[index])
    ) {
      form.trigger_words.splice(0, form.trigger_words.length, ...sanitized);
    }
    if (form.trigger_words.length) {
      errors.trigger_words = '';
    }
  },
  { deep: true }
);

watch(
  () => form.name,
  value => {
    if (value?.trim()) {
      errors.name = '';
    }
  }
);

watch(
  () => form.start_date,
  () => {
    if (form.start_date) {
      errors.start_date = '';
    }
    if (
      form.start_date &&
      form.end_date &&
      new Date(form.end_date) < new Date(form.start_date)
    ) {
      errors.end_date = t('CONTESTS.FORM_VALIDATION_DATE_ORDER');
    } else if (form.end_date) {
      errors.end_date = '';
    }
  }
);

watch(
  () => form.end_date,
  () => {
    if (form.end_date) {
      errors.end_date = '';
    }
    if (
      form.start_date &&
      form.end_date &&
      new Date(form.end_date) < new Date(form.start_date)
    ) {
      errors.end_date = t('CONTESTS.FORM_VALIDATION_DATE_ORDER');
    }
  }
);

watch(
  () => form.description,
  value => {
    if (value?.trim()) {
      errors.description = '';
    }
  }
);

watch(
  () => form.terms,
  value => {
    if (value?.trim()) {
      errors.terms = '';
    }
  }
);

const validateForm = () => {
  let isValid = true;
  if (!form.name?.trim()) {
    errors.name = t('CONTESTS.FORM_VALIDATION_REQUIRED');
    isValid = false;
  }
  if (!form.trigger_words.length) {
    errors.trigger_words = t('CONTESTS.FORM_VALIDATION_TRIGGER_WORDS');
    isValid = false;
  }
  if (!form.start_date) {
    errors.start_date = t('CONTESTS.FORM_VALIDATION_REQUIRED');
    isValid = false;
  }
  if (!form.end_date) {
    errors.end_date = t('CONTESTS.FORM_VALIDATION_REQUIRED');
    isValid = false;
  }
  if (
    form.start_date &&
    form.end_date &&
    new Date(form.end_date) < new Date(form.start_date)
  ) {
    errors.end_date = t('CONTESTS.FORM_VALIDATION_DATE_ORDER');
    isValid = false;
  }
  if (!form.description?.trim()) {
    errors.description = t('CONTESTS.FORM_VALIDATION_REQUIRED');
    isValid = false;
  }
  if (!form.terms?.trim()) {
    errors.terms = t('CONTESTS.FORM_VALIDATION_REQUIRED');
    isValid = false;
  }
  syncQuestionnaireErrors();
  form.questionnaire.forEach((item, index) => {
    if (!item?.question?.trim()) {
      errors.questionnaire[index] = t(
        'CONTESTS.FORM_VALIDATION_QUESTION_REQUIRED'
      );
      isValid = false;
    }
  });
  return isValid;
};

const handleSubmit = () => {
  if (!validateForm()) {
    return;
  }
  emit('submit', {
    ...form,
    trigger_words: [...form.trigger_words]
      .map(word => word.trim())
      .filter(Boolean),
    questionnaire: form.questionnaire
      .map(entry => ({
        question: entry?.question?.trim(),
        description: entry?.description?.trim(),
      }))
      .filter(entry => entry.question),
  });
};

const handleCancel = () => {
  emit('cancel');
};

const addQuestion = () => {
  form.questionnaire.push({
    question: '',
    description: '',
  });
  syncQuestionnaireErrors();
};

const removeQuestion = index => {
  if (form.questionnaire.length <= index) {
    return;
  }
  if (form.questionnaire.length === 1) {
    form.questionnaire[0] = {
      question: '',
      description: '',
    };
    errors.questionnaire[0] = '';
    return;
  }
  form.questionnaire.splice(index, 1);
  ensureQuestionnaireEntry();
  syncQuestionnaireErrors();
};

watch(
  () => form.questionnaire,
  () => {
    ensureQuestionnaireEntry();
    syncQuestionnaireErrors();
    form.questionnaire.forEach((entry, index) => {
      if (entry?.question?.trim()) {
        errors.questionnaire[index] = '';
      }
    });
  },
  { deep: true }
);
</script>

<template>
  <div
    class="flex max-h-[calc(100vh-6rem)] w-full overflow-y-auto [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden"
  >
    <section
      class="mx-auto flex w-full flex-col gap-4 rounded-xl bg-white dark:bg-[#22242b]"
    >
      <header class="flex flex-col gap-2">
        <div>
          <h2 class="text-lg font-semibold text-n-slate-12">
            {{ headingText }}
          </h2>
          <p class="text-sm text-n-slate-11">
            {{ t('CONTESTS.FORM_SUBHEADING') }}
          </p>
        </div>
      </header>

      <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
        <section
          class="grid gap-4 rounded-2xl border border-n-alpha-2 bg-n-alpha-1/40 p-4 dark:border-n-alpha-3 dark:bg-[#1f2129]"
        >
          <h3
            class="text-xs font-semibold uppercase tracking-wide text-n-slate-10"
          >
            {{ t('CONTESTS.FORM_SECTION_DETAILS') }}
          </h3>
          <div class="grid gap-4">
            <Input
              v-model="form.name"
              required
              :label="t('CONTESTS.FORM_NAME_LABEL')"
              :placeholder="t('CONTESTS.FORM_NAME_PLACEHOLDER')"
              :message="errors.name"
              :message-type="errors.name ? 'error' : 'info'"
            />
            <div class="grid gap-4 sm:grid-cols-2">
              <Input
                v-model="form.start_date"
                type="date"
                required
                :label="t('CONTESTS.FORM_START_DATE_LABEL')"
                :message="errors.start_date"
                :message-type="errors.start_date ? 'error' : 'info'"
              />
              <Input
                v-model="form.end_date"
                type="date"
                :min="form.start_date"
                required
                :label="t('CONTESTS.FORM_END_DATE_LABEL')"
                :message="errors.end_date"
                :message-type="errors.end_date ? 'error' : 'info'"
              />
            </div>
            <div class="space-y-2">
              <div class="flex items-center justify-between">
                <label class="text-sm font-medium text-n-slate-12">
                  {{ t('CONTESTS.FORM_TRIGGER_WORDS_LABEL') }}
                </label>
                <span class="text-xs text-n-slate-10">
                  {{
                    t('CONTESTS.FORM_TRIGGER_WORDS_COUNT', {
                      used: form.trigger_words.length,
                    })
                  }}
                </span>
              </div>
              <div
                class="w-full rounded-lg border px-3 py-2 bg-white dark:bg-n-alpha-black2"
                :class="
                  errors.trigger_words
                    ? 'border-n-ruby-8 dark:border-n-ruby-8'
                    : 'border-n-alpha-3 dark:border-n-alpha-4'
                "
              >
                <TagInput
                  v-model="form.trigger_words"
                  allow-create
                  :placeholder="t('CONTESTS.FORM_TRIGGER_WORDS_PLACEHOLDER')"
                  class="w-full"
                />
              </div>
              <p v-if="errors.trigger_words" class="text-xs text-n-ruby-9">
                {{ errors.trigger_words }}
              </p>
            </div>
          </div>
        </section>

        <section
          class="grid gap-3 rounded-2xl border border-n-alpha-2 bg-n-alpha-1/40 p-4 dark:border-n-alpha-3 dark:bg-[#1f2129]"
        >
          <h3
            class="text-xs font-semibold uppercase tracking-wide text-n-slate-10"
          >
            {{ t('CONTESTS.FORM_SECTION_CONTENT') }}
          </h3>
          <div class="grid gap-3">
            <TextArea
              v-model="form.description"
              auto-height
              resize
              :label="t('CONTESTS.FORM_DESCRIPTION_LABEL')"
              :placeholder="t('CONTESTS.FORM_DESCRIPTION_PLACEHOLDER')"
              :message="errors.description"
              :message-type="errors.description ? 'error' : 'info'"
            />
            <TextArea
              v-model="form.terms"
              auto-height
              resize
              :label="t('CONTESTS.FORM_TERMS_LABEL')"
              :placeholder="t('CONTESTS.FORM_TERMS_PLACEHOLDER')"
              :message="errors.terms"
              :message-type="errors.terms ? 'error' : 'info'"
            />
          </div>
        </section>

        <section
          class="grid gap-3 rounded-2xl border border-n-alpha-2 p-4 dark:border-n-alpha-3 dark:bg-[#1f2129]"
        >
          <header class="flex flex-col gap-1">
            <h3
              class="text-xs font-semibold uppercase tracking-wide text-n-slate-10"
            >
              {{ t('CONTESTS.FORM_SECTION_QUESTIONNAIRE') }}
            </h3>
            <p class="text-sm text-n-slate-11">
              {{ t('CONTESTS.FORM_SECTION_QUESTIONNAIRE_HELP') }}
            </p>
          </header>

          <div class="space-y-4">
            <div
              v-for="(item, index) in form.questionnaire"
              :key="`question-${index}`"
              class="rounded-xl border border-n-alpha-1 bg-n-gray-1 p-4 dark:bg-[#1c1f25]"
            >
              <div class="flex items-center justify-between gap-2 pb-2">
                <h4 class="text-sm font-semibold text-n-slate-12">
                  {{
                    t('CONTESTS.FORM_QUESTIONNAIRE_ITEM_LABEL', {
                      number: index + 1,
                    })
                  }}
                </h4>
                <Button
                  v-if="form.questionnaire.length > 1"
                  slate
                  ghost
                  icon="i-lucide-trash-2"
                  type="button"
                  xs
                  :aria-label="t('CONTESTS.FORM_QUESTIONNAIRE_REMOVE')"
                  @click="removeQuestion(index)"
                />
              </div>
              <div class="space-y-3">
                <Input
                  v-model="item.question"
                  required
                  :label="t('CONTESTS.FORM_QUESTION_LABEL')"
                  :placeholder="t('CONTESTS.FORM_QUESTION_PLACEHOLDER')"
                  :message="errors.questionnaire[index]"
                  :message-type="errors.questionnaire[index] ? 'error' : 'info'"
                />
                <TextArea
                  v-model="item.description"
                  auto-height
                  resize
                  :label="t('CONTESTS.FORM_QUESTION_DESCRIPTION_LABEL')"
                  :placeholder="
                    t('CONTESTS.FORM_QUESTION_DESCRIPTION_PLACEHOLDER')
                  "
                />
              </div>
            </div>
            <div
              v-if="!form.questionnaire.length"
              class="rounded-xl border border-dashed border-n-alpha-3 bg-white p-4 text-sm text-n-slate-11 dark:bg-[#1c1f25]"
            >
              {{ t('CONTESTS.FORM_QUESTIONNAIRE_EMPTY') }}
            </div>
            <div class="flex">
              <Button type="button" icon="i-lucide-plus" @click="addQuestion">
                {{ t('CONTESTS.FORM_QUESTIONNAIRE_ADD') }}
              </Button>
            </div>
          </div>
        </section>

        <footer
          class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end sm:gap-3"
        >
          <Button slate ghost type="button" @click="handleCancel">
            {{ t('CONTESTS.FORM_CANCEL') }}
          </Button>
          <Button type="submit">
            {{ submitText }}
          </Button>
        </footer>
      </form>
    </section>
  </div>
</template>
