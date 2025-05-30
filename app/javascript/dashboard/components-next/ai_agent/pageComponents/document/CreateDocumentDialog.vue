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
  selectedDocument: {
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

const name = ref('');
const externalLink = ref('');
const topicId = ref(null);
const topics = ref([]);
const isLoading = ref(false);

const errors = ref({
  name: '',
  externalLink: '',
  topicId: '',
});

const validateForm = () => {
  errors.value.name = name.value.trim()
    ? ''
    : t('AI_AGENT.DOCUMENTS.NAME.ERROR');
  errors.value.externalLink = externalLink.value.trim()
    ? ''
    : t('AI_AGENT.DOCUMENTS.EXTERNAL_LINK.ERROR');
  errors.value.topicId = topicId.value
    ? ''
    : t('AI_AGENT.DOCUMENTS.TOPIC_ID.ERROR');

  // Validate URL format
  if (externalLink.value.trim() && !isValidURL(externalLink.value.trim())) {
    errors.value.externalLink = t('AI_AGENT.DOCUMENTS.EXTERNAL_LINK.INVALID');
  }

  isInitialValidation.value = true;
};

const isValidURL = url => {
  try {
    new URL(url);
    return true;
  } catch (error) {
    return false;
  }
};

const isFormValid = computed(() => {
  return (
    !errors.value.name && !errors.value.externalLink && !errors.value.topicId
  );
});

const handleNameChange = e => {
  name.value = e.target.value;
  validateForm();
};

const handleExternalLinkChange = e => {
  externalLink.value = e.target.value;
  validateForm();
};

const handleTopicChange = value => {
  topicId.value = value;
  validateForm();
};

const resetForm = () => {
  name.value = '';
  externalLink.value = '';
  topicId.value = null;
  errors.value = {
    name: '',
    externalLink: '',
    topicId: '',
  };
  isInitialValidation.value = false;
};

const getDocumentData = () => {
  return {
    name: name.value.trim(),
    external_link: externalLink.value.trim(),
    topic_id: topicId.value,
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
      await store.dispatch('aiAgentDocuments/create', getDocumentData());
    } else {
      await store.dispatch('aiAgentDocuments/update', {
        id: props.selectedDocument.id,
        ...getDocumentData(),
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
  () => props.selectedDocument,
  newDocument => {
    if (newDocument && props.type === 'edit') {
      name.value = newDocument.name || '';
      externalLink.value = newDocument.external_link || '';
      topicId.value = newDocument.topic?.id || null;
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
        ? $t('AI_AGENT.DOCUMENTS.ADD')
        : $t('AI_AGENT.DOCUMENTS.EDIT')
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
          {{ $t('AI_AGENT.DOCUMENTS.TOPIC_ID.LABEL') }}
        </label>
        <ComboBox
          id="topic"
          v-model="topicId"
          :options="topics"
          :placeholder="$t('AI_AGENT.DOCUMENTS.TOPIC_ID.PLACEHOLDER')"
          :has-error="isInitialValidation && !!errors.topicId"
          :message="isInitialValidation ? errors.topicId : ''"
          class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
        />
      </div>
      <Input
        v-model="name"
        :label="$t('AI_AGENT.DOCUMENTS.NAME.LABEL')"
        :placeholder="$t('AI_AGENT.DOCUMENTS.NAME.PLACEHOLDER')"
        :message="isInitialValidation ? errors.name : ''"
        :message-type="isInitialValidation && errors.name ? 'error' : 'info'"
        @input="handleNameChange"
      />
      <Input
        v-model="externalLink"
        :label="$t('AI_AGENT.DOCUMENTS.EXTERNAL_LINK.LABEL')"
        :placeholder="$t('AI_AGENT.DOCUMENTS.EXTERNAL_LINK.PLACEHOLDER')"
        :message="isInitialValidation ? errors.externalLink : ''"
        :message-type="
          isInitialValidation && errors.externalLink ? 'error' : 'info'
        "
        @input="handleExternalLinkChange"
      />
    </div>
  </Dialog>
</template>
