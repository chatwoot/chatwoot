<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['edit', 'create'].includes(value),
  },
  topic: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

// Get UI flags with safe fallback if the getter is not available
let uiFlags;
try {
  uiFlags = useMapGetter('aiAgentTopics/getUIFlags');
} catch (error) {
  // Silent error handling with fallback value
  uiFlags = { value: { creatingItem: false, updatingItem: false } };
}

const formState = {
  uiFlags,
};

const initialState = {
  name: '',
  description: '',
};

const state = reactive({ ...initialState });

const validationRules = {
  name: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => {
  // Safely access properties with optional chaining
  return (
    formState.uiFlags?.value?.creatingItem ||
    formState.uiFlags?.value?.updatingItem ||
    false
  );
});

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error ? t(`AI_AGENT.TOPICS.${errorKey}.ERROR`) : '';
};

const formErrors = computed(() => ({
  name: getErrorMessage('name', 'NAME'),
  description: getErrorMessage('description', 'DESCRIPTION'),
}));

const handleCancel = () => emit('cancel');

const prepareTopicDetails = () => ({
  name: state.name,
  description: state.description,
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', prepareTopicDetails());
};

const updateStateFromTopic = topic => {
  if (!topic) return;

  const { name, description } = topic;

  Object.assign(state, {
    name: name || '',
    description: description || '',
  });
};

watch(
  () => props.topic,
  newTopic => {
    if (props.mode === 'edit' && newTopic) {
      updateStateFromTopic(newTopic);
    }
  },
  { immediate: true }
);
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.name"
      :label="t('AI_AGENT.TOPICS.NAME.LABEL')"
      :placeholder="t('AI_AGENT.TOPICS.NAME.PLACEHOLDER')"
      :message="formErrors.name"
      :message-type="formErrors.name ? 'error' : 'info'"
    />

    <Editor
      v-model="state.description"
      :label="t('AI_AGENT.TOPICS.DESCRIPTION.LABEL')"
      :placeholder="t('AI_AGENT.TOPICS.DESCRIPTION.PLACEHOLDER')"
      :message="formErrors.description"
      :message-type="formErrors.description ? 'error' : 'info'"
    />

    <div class="flex items-center justify-between w-full gap-3">
      <Button
        type="button"
        variant="faded"
        color="slate"
        :label="t('CANCEL')"
        class="w-full bg-n-alpha-2 n-blue-text hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        type="submit"
        :label="
          t(
            `AI_AGENT.TOPICS.${props.mode.toUpperCase() === 'CREATE' ? 'ADD' : 'EDIT'}`
          )
        "
        class="w-full"
        :is-loading="isLoading"
        :disabled="isLoading"
      />
    </div>
  </form>
</template>
