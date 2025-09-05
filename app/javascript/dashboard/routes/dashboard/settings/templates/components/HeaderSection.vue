<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
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

const headerData = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value),
});

const setHeaderFormat = format => {
  headerData.value = {
    ...headerData.value,
    format,
  };
};
const exampleKey = computed(() => {
  return props.parameterType === 'positional'
    ? 'header_text'
    : 'header_text_named_params';
});

const headerTextData = computed({
  get: () => ({
    text: headerData.value.text,
    examples: headerData.value.example[exampleKey.value],
    error: headerData.value.error,
  }),
  set: ({ text, examples, error }) => {
    headerData.value = {
      ...headerData.value,
      text,
      example: {
        ...headerData.value.example,
        [exampleKey.value]: [...examples],
      },
      error,
    };
  },
});

const mediaFormats = ['IMAGE', 'VIDEO', 'DOCUMENT'];

const headerformats = [
  { value: 'TEXT', label: 'Text', icon: 'i-lucide-type' },
  { value: 'IMAGE', label: 'Image', icon: 'i-lucide-image' },
  { value: 'VIDEO', label: 'Video', icon: 'i-lucide-video' },
  { value: 'DOCUMENT', label: 'Document', icon: 'i-lucide-file' },
  { value: 'LOCATION', label: 'Location', icon: 'i-lucide-map-pin' },
];
</script>

<template>
  <div class="bg-n-solid-2 rounded-lg p-4 border border-n-weak">
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center gap-3">
        <span class="i-lucide-layout-panel-top size-5 text-n-slate-11" />
        <h4 class="font-medium text-n-slate-12">
          {{ t('SETTINGS.TEMPLATES.BUILDER.HEADER.TITLE') }}
        </h4>
        <span class="text-xs text-n-slate-11 bg-n-solid-3 px-2 py-1 rounded">
          {{ t('SETTINGS.TEMPLATES.BUILDER.OPTIONAL') }}
        </span>
      </div>
      <div class="flex items-center">
        <Switch v-model="headerData.enabled" />
      </div>
    </div>

    <div v-if="headerData.enabled" class="space-y-4">
      <!-- Header Type Selection -->
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('SETTINGS.TEMPLATES.BUILDER.HEADER.TYPE') }}
        </label>
        <div class="flex gap-2">
          <NextButton
            v-for="format in headerformats"
            :key="format.value"
            :label="format.label"
            :icon="format.icon"
            size="sm"
            :variant="headerData.format === format.value ? 'solid' : 'outline'"
            :color="headerData.format === format.value ? 'blue' : 'slate'"
            @click="setHeaderFormat(format.value)"
          />
        </div>
      </div>

      <!-- Text Header -->
      <div v-if="headerData.format === 'TEXT'">
        <VariableSection
          v-model="headerTextData"
          input-type="input"
          :max-length="60"
          :placeholder="t('SETTINGS.TEMPLATES.BUILDER.HEADER.TEXT_PLACEHOLDER')"
          :label="t('SETTINGS.TEMPLATES.BUILDER.HEADER.TEXT_LABEL')"
          :help-text="t('SETTINGS.TEMPLATES.BUILDER.HEADER.TEXT_HELP')"
          :parameter-type="parameterType"
          :max-variables="1"
        />
      </div>

      <!-- Media  -->
      <div v-if="mediaFormats.includes(headerData.format)" class="space-y-4">
        <div
          class="border-2 border-dashed border-n-weak rounded-lg p-6 text-center bg-n-solid-1"
        >
          <span
            :class="headerformats.find(m => m.value === headerData.format)"
            class="size-12 text-n-slate-9 mx-auto mb-3"
          />
          <p class="text-sm text-n-slate-11 mb-2">
            {{ t('SETTINGS.TEMPLATES.BUILDER.HEADER.MEDIA_UPLOAD') }}
          </p>
          <NextButton
            faded
            slate
            xs
            icon="i-lucide-upload"
            :label="t('SETTINGS.TEMPLATES.BUILDER.HEADER.UPLOAD_BTN')"
          />
        </div>
      </div>
    </div>
    <div v-else class="text-center py-8 text-n-slate-11">
      <span class="i-lucide-layout-panel-top size-12 mx-auto mb-3 opacity-50" />
      <p class="text-sm">
        {{ t('SETTINGS.TEMPLATES.BUILDER.HEADER.DISABLED_TEXT') }}
      </p>
    </div>
  </div>
</template>
