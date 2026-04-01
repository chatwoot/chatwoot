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
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainAssistants/getUIFlags'),
};

const initialState = {
  name: '',
  description: '',
  productName: '',
  featureFaq: false,
  featureMemory: false,
  featureCitation: false,
};

const state = reactive({ ...initialState });

const validationRules = {
  name: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) },
  productName: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const formErrors = computed(() => ({
  name: v$.value.name.$error ? t('CAPTAIN.ASSISTANTS.FORM.NAME.ERROR') : '',
  description: v$.value.description.$error
    ? t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.ERROR')
    : '',
  productName: v$.value.productName.$error
    ? t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.ERROR')
    : '',
}));

const submitLabel = computed(() =>
  props.mode === 'create' ? t('CAPTAIN.FORM.CREATE') : t('CAPTAIN.FORM.EDIT')
);

const handleCancel = () => emit('cancel');

const prepareAssistantDetails = () => ({
  name: state.name,
  description: state.description,
  config: {
    product_name: state.productName,
    feature_faq: state.featureFaq,
    feature_memory: state.featureMemory,
    feature_citation: state.featureCitation,
  },
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', prepareAssistantDetails());
};

const updateStateFromAssistant = assistant => {
  if (!assistant) return;

  const { name, description, config } = assistant;

  Object.assign(state, {
    name,
    description,
    productName: config.product_name,
    featureFaq: config.feature_faq || false,
    featureMemory: config.feature_memory || false,
    featureCitation: config.feature_citation || false,
  });
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
  <form
    class="flex flex-col gap-6 rounded-xl border border-outline-variant/10 bg-surface-container-low p-5"
    @submit.prevent="handleSubmit"
  >
    <div class="grid grid-cols-1 gap-5 md:grid-cols-2">
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

    <fieldset
      class="space-y-2 rounded-xl border border-outline-variant/10 bg-surface-container px-4 py-3"
    >
      <legend
        class="px-1 text-xs font-semibold uppercase tracking-wider text-on-surface-variant"
      >
        {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.TITLE') }}
      </legend>

      <label class="flex items-center gap-2 text-sm text-on-surface">
        <input
          v-model="state.featureFaq"
          type="checkbox"
          class="!mb-0 rounded border-outline-variant/40"
        />
        <span>{{
          t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONVERSATION_FAQS')
        }}</span>
      </label>

      <label class="flex items-center gap-2 text-sm text-on-surface">
        <input
          v-model="state.featureMemory"
          type="checkbox"
          class="!mb-0 rounded border-outline-variant/40"
        />
        <span>{{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_MEMORIES') }}</span>
      </label>

      <label class="flex items-center gap-2 text-sm text-on-surface">
        <input
          v-model="state.featureCitation"
          type="checkbox"
          class="!mb-0 rounded border-outline-variant/40"
        />
        <span>{{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CITATIONS') }}</span>
      </label>
    </fieldset>

    <div
      class="flex w-full items-center justify-between gap-3 border-t border-outline-variant/15 pt-4"
    >
      <Button
        type="button"
        faded
        slate
        :label="t('CAPTAIN.FORM.CANCEL')"
        class="w-full"
        @click="handleCancel"
      />
      <Button
        type="submit"
        solid
        teal
        :label="submitLabel"
        class="w-full"
        :is-loading="isLoading"
        :disabled="isLoading"
      />
    </div>
  </form>
</template>
