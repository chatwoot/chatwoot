<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Accordion from 'dashboard/components-next/Accordion/Accordion.vue';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['edit', 'create'].includes(value),
  },
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainAssistants/getUIFlags'),
};

const initialState = {
  name: '',
  description: '',
  productName: '',
  welcomeMessage: '',
  handoffMessage: '',
  resolutionMessage: '',
  instructions: '',
  features: {
    conversationFaqs: false,
    memories: false,
  },
};

const state = reactive({ ...initialState });

const validationRules = {
  name: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) },
  productName: { required, minLength: minLength(1) },
  welcomeMessage: { minLength: minLength(1) },
  handoffMessage: { minLength: minLength(1) },
  resolutionMessage: { minLength: minLength(1) },
  instructions: { minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const getErrorMessage = field => {
  return v$.value[field].$error ? v$.value[field].$errors[0].$message : '';
};

const formErrors = computed(() => ({
  name: getErrorMessage('name'),
  description: getErrorMessage('description'),
  productName: getErrorMessage('productName'),
  welcomeMessage: getErrorMessage('welcomeMessage'),
  handoffMessage: getErrorMessage('handoffMessage'),
  resolutionMessage: getErrorMessage('resolutionMessage'),
  instructions: getErrorMessage('instructions'),
}));

const updateStateFromAssistant = assistant => {
  const { config = {} } = assistant;
  state.name = assistant.name;
  state.description = assistant.description;
  state.productName = config.product_name;
  state.welcomeMessage = config.welcome_message;
  state.handoffMessage = config.handoff_message;
  state.resolutionMessage = config.resolution_message;
  state.instructions = config.instructions;
  state.features = {
    conversationFaqs: config.feature_faq || false,
    memories: config.feature_memory || false,
  };
};

const handleBasicInfoUpdate = async () => {
  const result = await Promise.all([
    v$.value.name.$validate(),
    v$.value.description.$validate(),
    v$.value.productName.$validate(),
  ]).then(results => results.every(Boolean));
  if (!result) return;

  const payload = {
    name: state.name,
    description: state.description,
    config: {
      ...props.assistant.config,
      product_name: state.productName,
    },
  };

  emit('submit', payload);
};

const handleSystemMessagesUpdate = async () => {
  const result = await Promise.all([
    v$.value.welcomeMessage.$validate(),
    v$.value.handoffMessage.$validate(),
    v$.value.resolutionMessage.$validate(),
  ]).then(results => results.every(Boolean));
  if (!result) return;

  const payload = {
    config: {
      ...props.assistant.config,
      welcome_message: state.welcomeMessage,
      handoff_message: state.handoffMessage,
      resolution_message: state.resolutionMessage,
    },
  };

  emit('submit', payload);
};

const handleInstructionsUpdate = async () => {
  const result = await v$.value.instructions.$validate();
  if (!result) return;

  const payload = {
    config: {
      ...props.assistant.config,
      instructions: state.instructions,
    },
  };

  emit('submit', payload);
};

const handleFeaturesUpdate = () => {
  const payload = {
    config: {
      ...props.assistant.config,
      feature_faq: state.features.conversationFaqs,
      feature_memory: state.features.memories,
    },
  };

  emit('submit', payload);
};

watch(
  () => props.assistant,
  newAssistant => {
    if (props.mode === 'edit' && newAssistant) {
      updateStateFromAssistant(newAssistant);
    }
  },
  { immediate: true }
);
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <!-- Basic Information Section -->
    <Accordion
      :title="t('CAPTAIN.ASSISTANTS.FORM.SECTIONS.BASIC_INFO')"
      is-open
    >
      <div class="flex flex-col gap-4 pt-4">
        <Input
          v-model="state.name"
          :label="t('CAPTAIN.ASSISTANTS.FORM.NAME.LABEL')"
          :placeholder="t('CAPTAIN.ASSISTANTS.FORM.NAME.PLACEHOLDER')"
          :message="formErrors.name"
          :message-type="formErrors.name ? 'error' : 'info'"
        />

        <Editor
          v-model="state.description"
          :label="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.LABEL')"
          :placeholder="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.PLACEHOLDER')"
          :message="formErrors.description"
          :message-type="formErrors.description ? 'error' : 'info'"
        />

        <Input
          v-model="state.productName"
          :label="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.LABEL')"
          :placeholder="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.PLACEHOLDER')"
          :message="formErrors.productName"
          :message-type="formErrors.productName ? 'error' : 'info'"
        />

        <div class="flex justify-end">
          <Button
            size="small"
            :loading="isLoading"
            @click="handleBasicInfoUpdate"
          >
            {{ t('CAPTAIN.ASSISTANTS.FORM.UPDATE') }}
          </Button>
        </div>
      </div>
    </Accordion>

    <!-- Instructions Section -->
    <Accordion :title="t('CAPTAIN.ASSISTANTS.FORM.SECTIONS.INSTRUCTIONS')">
      <div class="flex flex-col gap-4 pt-4">
        <Editor
          v-model="state.instructions"
          :placeholder="t('CAPTAIN.ASSISTANTS.FORM.INSTRUCTIONS.PLACEHOLDER')"
          :message="formErrors.instructions"
          :max-length="20000"
          :message-type="formErrors.instructions ? 'error' : 'info'"
        />

        <div class="flex justify-end">
          <Button
            size="small"
            :loading="isLoading"
            :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
            @click="handleInstructionsUpdate"
          />
        </div>
      </div>
    </Accordion>

    <!-- Greeting Messages Section -->
    <Accordion :title="t('CAPTAIN.ASSISTANTS.FORM.SECTIONS.SYSTEM_MESSAGES')">
      <div class="flex flex-col gap-4 pt-4">
        <Editor
          v-model="state.handoffMessage"
          :label="t('CAPTAIN.ASSISTANTS.FORM.HANDOFF_MESSAGE.LABEL')"
          :placeholder="
            t('CAPTAIN.ASSISTANTS.FORM.HANDOFF_MESSAGE.PLACEHOLDER')
          "
          :message="formErrors.handoffMessage"
          :message-type="formErrors.handoffMessage ? 'error' : 'info'"
        />

        <Editor
          v-model="state.resolutionMessage"
          :label="t('CAPTAIN.ASSISTANTS.FORM.RESOLUTION_MESSAGE.LABEL')"
          :placeholder="
            t('CAPTAIN.ASSISTANTS.FORM.RESOLUTION_MESSAGE.PLACEHOLDER')
          "
          :message="formErrors.resolutionMessage"
          :message-type="formErrors.resolutionMessage ? 'error' : 'info'"
        />

        <div class="flex justify-end">
          <Button
            size="small"
            :loading="isLoading"
            :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
            @click="handleSystemMessagesUpdate"
          />
        </div>
      </div>
    </Accordion>

    <!-- Features Section -->
    <Accordion :title="t('CAPTAIN.ASSISTANTS.FORM.SECTIONS.FEATURES')">
      <div class="flex flex-col gap-4 pt-4">
        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.TITLE') }}
          </label>
          <div class="flex flex-col gap-2">
            <label class="flex items-center gap-2">
              <input
                v-model="state.features.conversationFaqs"
                type="checkbox"
                class="form-checkbox"
              />
              {{
                t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONVERSATION_FAQS')
              }}
            </label>
            <label class="flex items-center gap-2">
              <input
                v-model="state.features.memories"
                type="checkbox"
                class="form-checkbox"
              />
              {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_MEMORIES') }}
            </label>
          </div>
        </div>

        <div class="flex justify-end">
          <Button
            size="small"
            :loading="isLoading"
            :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
            @click="handleFeaturesUpdate"
          />
        </div>
      </div>
    </Accordion>
  </form>
</template>
