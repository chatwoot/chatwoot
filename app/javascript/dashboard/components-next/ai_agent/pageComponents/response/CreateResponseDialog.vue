<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
  selectedResponse: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['close']);
const store = useStore();
const { t } = useI18n();

const dialogRef = ref(null);
const isSaving = ref(false);
const isInitialValidation = ref(false);

const question = ref('');
const answer = ref('');
const topicId = ref(null);
const topics = ref([]);
const isLoading = ref(false);

const errors = ref({
  question: '',
  answer: '',
  topicId: '',
});

const validateForm = () => {
  errors.value.question = question.value.trim()
    ? ''
    : t('AI_AGENT.RESPONSES.QUESTION.ERROR');
  errors.value.answer = answer.value.trim()
    ? ''
    : t('AI_AGENT.RESPONSES.ANSWER.ERROR');
  errors.value.topicId = topicId.value
    ? ''
    : t('AI_AGENT.RESPONSES.TOPIC_ID.ERROR');
  isInitialValidation.value = true;
};

const isFormValid = computed(() => {
  return (
    !errors.value.question && !errors.value.answer && !errors.value.topicId
  );
});

const handleQuestionChange = e => {
  question.value = e.target.value;
  validateForm();
};

const handleAnswerChange = e => {
  answer.value = e.target.value;
  validateForm();
};

// Watch for topicId changes and validate
watch(
  () => topicId.value,
  () => {
    if (isInitialValidation.value) {
      validateForm();
    }
  }
);

const resetForm = () => {
  question.value = '';
  answer.value = '';
  topicId.value = null;
  errors.value = {
    question: '',
    answer: '',
    topicId: '',
  };
  isInitialValidation.value = false;
};

const getResponseData = () => {
  return {
    question: question.value.trim(),
    answer: answer.value.trim(),
    topicId: topicId.value,
  };
};

const onClose = () => {
  resetForm();
  emit('close');
};

const onSubmit = async () => {
  validateForm();
  if (!isFormValid.value) return;

  isSaving.value = true;
  try {
    if (props.type === 'create') {
      await store.dispatch('aiAgentResponses/create', getResponseData());
    } else {
      await store.dispatch('aiAgentResponses/update', {
        id: props.selectedResponse.id,
        ...getResponseData(),
      });
    }
    dialogRef.value.close();
  } catch (error) {
    // Handle error
  } finally {
    isSaving.value = false;
  }
};

const fetchTopics = async () => {
  isLoading.value = true;
  try {
    await store.dispatch('aiAgentTopics/get');
    const allTopics = store.getters['aiAgentTopics/getTopics'];
    topics.value = allTopics.map(topic => ({
      value: topic.id,
      label: topic.name,
    }));
  } catch (error) {
    // Handle error
  } finally {
    isLoading.value = false;
  }
};

watch(
  () => props.selectedResponse,
  newResponse => {
    if (newResponse && props.type === 'edit') {
      question.value = newResponse.question || '';
      answer.value = newResponse.answer || '';
      topicId.value = newResponse.topic?.id || null;
    } else {
      resetForm();
    }
  },
  { immediate: true }
);

fetchTopics();

defineExpose({
  dialogRef,
});
</script>

<template>
  <Dialog
    ref="dialogRef"
    :heading="
      props.type === 'create'
        ? $t('AI_AGENT.RESPONSES.ADD')
        : $t('AI_AGENT.RESPONSES.EDIT')
    "
    :confirm-text="$t('SAVE')"
    :cancel-text="$t('CANCEL')"
    :confirm-disabled="!isFormValid || isSaving"
    :is-confirm-loading="isSaving"
    @confirm="onSubmit"
    @cancel="onClose"
    @close="onClose"
  >
    <div class="space-y-4">
      <div class="flex flex-col gap-1">
        <label for="topic" class="mb-0.5 text-sm font-medium text-n-slate-12">
          {{ $t('AI_AGENT.RESPONSES.TOPIC_ID.LABEL') }}
        </label>
        <ComboBox
          id="topic"
          v-model="topicId"
          :options="topics"
          :placeholder="$t('AI_AGENT.RESPONSES.TOPIC_ID.PLACEHOLDER')"
          :has-error="isInitialValidation && !!errors.topicId"
          :message="isInitialValidation ? errors.topicId : ''"
          class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
        />
      </div>
      <Input
        v-model="question"
        :label="$t('AI_AGENT.RESPONSES.QUESTION.LABEL')"
        :placeholder="$t('AI_AGENT.RESPONSES.QUESTION.PLACEHOLDER')"
        :message="isInitialValidation ? errors.question : ''"
        :message-type="
          isInitialValidation && errors.question ? 'error' : 'info'
        "
        @input="handleQuestionChange"
      />
      <Input
        v-model="answer"
        :label="$t('AI_AGENT.RESPONSES.ANSWER.LABEL')"
        :placeholder="$t('AI_AGENT.RESPONSES.ANSWER.PLACEHOLDER')"
        :message="isInitialValidation ? errors.answer : ''"
        :message-type="isInitialValidation && errors.answer ? 'error' : 'info'"
        multiline
        rows="6"
        @input="handleAnswerChange"
      />
    </div>
  </Dialog>
</template>
