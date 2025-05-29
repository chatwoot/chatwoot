<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import TopicForm from './TopicForm.vue';

const props = defineProps({
  selectedTopic: {
    type: Object,
    default: () => ({}),
  },
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
});
const emit = defineEmits(['close']);
const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const topicForm = ref(null);

const updateTopic = topicDetails =>
  store.dispatch('aiagentTopics/update', {
    id: props.selectedTopic.id,
    ...topicDetails,
  });

const i18nKey = computed(() => `AIAGENT.TOPICS.${props.type.toUpperCase()}`);

const createTopic = topicDetails =>
  store.dispatch('aiagentTopics/create', topicDetails);

const handleSubmit = async updatedTopic => {
  try {
    if (props.type === 'edit') {
      await updateTopic(updatedTopic);
    } else {
      await createTopic(updatedTopic);
    }
    useAlert(t(`${i18nKey.value}.SUCCESS_MESSAGE`));
    dialogRef.value.close();
  } catch (error) {
    const errorMessage = error?.message || t(`${i18nKey.value}.ERROR_MESSAGE`);
    useAlert(errorMessage);
  }
};

const handleClose = () => {
  emit('close');
};

const handleCancel = () => {
  dialogRef.value.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="t(`${i18nKey}.TITLE`)"
    :description="t('AIAGENT.TOPICS.FORM_DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
    @close="handleClose"
  >
    <TopicForm
      ref="topicForm"
      :mode="type"
      :topic="selectedTopic"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
    <template #footer />
  </Dialog>
</template>
