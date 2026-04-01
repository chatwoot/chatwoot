<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();

const initialState = {
  name: '',
  description: '',
  productName: '',
  features: {
    conversationFaqs: false,
    memories: false,
    citations: false,
  },
};

const state = reactive({ ...initialState });

const validationRules = {
  name: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) },
  productName: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const getErrorMessage = field => {
  return v$.value[field].$error ? v$.value[field].$errors[0].$message : '';
};

const formErrors = computed(() => ({
  name: getErrorMessage('name'),
  description: getErrorMessage('description'),
  productName: getErrorMessage('productName'),
}));

const updateStateFromAssistant = assistant => {
  const { config = {} } = assistant;
  state.name = assistant.name;
  state.description = assistant.description;
  state.productName = config.product_name;
  state.features = {
    conversationFaqs: config.feature_faq || false,
    memories: config.feature_memory || false,
    citations: config.feature_citation || false,
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
      feature_faq: state.features.conversationFaqs,
      feature_memory: state.features.memories,
      feature_citation: state.features.citations,
    },
  };

  emit('submit', payload);
};

watch(
  () => props.assistant,
  newAssistant => {
    if (newAssistant) updateStateFromAssistant(newAssistant);
  },
  { immediate: true }
);
</script>

<template>
  <div
    class="flex flex-col gap-6 rounded-xl border border-outline-variant/10 bg-surface-container-low p-6 shadow-sm"
  >
    <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
      <Input
        v-model="state.name"
        :label="t('CAPTAIN.ASSISTANTS.FORM.NAME.LABEL')"
        :placeholder="t('CAPTAIN.ASSISTANTS.FORM.NAME.PLACEHOLDER')"
        :message="formErrors.name"
        :message-type="formErrors.name ? 'error' : 'info'"
      />

      <Input
        v-model="state.productName"
        :label="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.LABEL')"
        :placeholder="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.PLACEHOLDER')"
        :message="formErrors.productName"
        :message-type="formErrors.productName ? 'error' : 'info'"
      />
    </div>

    <Editor
      v-model="state.description"
      :label="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.PLACEHOLDER')"
      :message="formErrors.description"
      :message-type="formErrors.description ? 'error' : 'info'"
      class="z-0"
    />

    <div
      class="flex flex-col gap-3 rounded-xl border border-outline-variant/10 bg-surface-container px-4 py-3"
    >
      <div class="flex items-center gap-2">
        <Icon icon="i-lucide-sparkles" class="size-4 shrink-0 text-secondary" />
        <label
          class="mb-0 text-xs font-semibold uppercase tracking-wider text-on-surface-variant"
        >
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.TITLE') }}
        </label>
      </div>
      <div class="flex flex-col gap-2">
        <label class="flex items-center gap-2 text-sm text-on-surface">
          <input
            v-model="state.features.conversationFaqs"
            type="checkbox"
            class="!mb-0 rounded border-outline-variant/40"
          />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONVERSATION_FAQS') }}
        </label>
        <label class="flex items-center gap-2 text-sm text-on-surface">
          <input
            v-model="state.features.memories"
            type="checkbox"
            class="!mb-0 rounded border-outline-variant/40"
          />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_MEMORIES') }}
        </label>
        <label class="flex items-center gap-2 text-sm text-on-surface">
          <input
            v-model="state.features.citations"
            type="checkbox"
            class="!mb-0 rounded border-outline-variant/40"
          />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CITATIONS') }}
        </label>
      </div>
    </div>

    <div class="flex justify-end border-t border-outline-variant/15 pt-4">
      <Button
        solid
        teal
        md
        trailing-icon
        icon="i-lucide-save"
        :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
        class="font-semibold"
        @click="handleBasicInfoUpdate"
      />
    </div>
  </div>
</template>
