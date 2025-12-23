<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import VariableSection from './VariableSection.vue';

const props = defineProps({
  modelValue: {
    type: Object,
    required: true,
  },
  parameterType: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const bodyData = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value),
});

const exampleKey = computed(() => {
  return props.parameterType === 'positional'
    ? 'body_text'
    : 'body_text_named_params';
});

const bodyTextData = computed({
  get: () => ({
    text: bodyData.value.text,
    examples: bodyData.value.example[exampleKey.value],
    error: bodyData.value.error,
  }),
  set: ({ text, examples, error }) => {
    bodyData.value = {
      ...bodyData.value,
      text,
      example: {
        ...bodyData.value.example,
        [exampleKey.value]: examples,
      },
      error,
    };
  },
});
</script>

<template>
  <div class="bg-n-solid-2 rounded-lg p-4 border border-n-weak">
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center gap-3">
        <span class="i-lucide-align-left size-5 text-n-slate-11" />
        <h4 class="font-medium text-n-slate-12">
          {{ t('SETTINGS.TEMPLATES.BUILDER.BODY.TITLE') }}
        </h4>
        <span class="text-xs text-red-600 bg-red-50 px-2 py-1 rounded">
          {{ t('SETTINGS.TEMPLATES.BUILDER.REQUIRED') }}
        </span>
      </div>
    </div>

    <!-- Content -->
    <VariableSection
      v-model="bodyTextData"
      input-type="textarea"
      :max-length="1024"
      :placeholder="t('SETTINGS.TEMPLATES.BUILDER.BODY.TEXT_PLACEHOLDER')"
      :label="t('SETTINGS.TEMPLATES.BUILDER.BODY.TEXT_LABEL')"
      :parameter-type="parameterType"
    />
  </div>
</template>
