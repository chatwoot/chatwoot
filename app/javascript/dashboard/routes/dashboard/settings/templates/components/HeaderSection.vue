<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import VariableSection from './VariableSection.vue';
import FileUpload from 'dashboard/components-next/file-upload/FileUpload.vue';
import { MEDIA_FORMATS, UPLOAD_CONFIG } from 'dashboard/helper/templateHelper';

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
const getUploadConfig = computed(() => {
  return UPLOAD_CONFIG[headerData.value.format];
});

const headerFormats = [
  { value: 'TEXT', label: 'Text', icon: 'i-lucide-type' },
  { value: 'IMAGE', label: 'Image', icon: 'i-lucide-image' },
  { value: 'VIDEO', label: 'Video', icon: 'i-lucide-video' },
  { value: 'DOCUMENT', label: 'Document', icon: 'i-lucide-file-text' },
  { value: 'LOCATION', label: 'Location', icon: 'i-lucide-map-pin' },
];

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

const setHeaderFormat = format => {
  if (MEDIA_FORMATS.includes(format)) {
    const newValue = {
      ...headerData.value,
      format,
      text: '',
      example: {
        ...headerData.value.example,
        header_text: [],
        header_text_named_params: [],
      },
      media: {},
      error: '',
    };
    headerData.value = newValue;
  } else {
    headerData.value = {
      ...headerData.value,
      format,
      media: {},
      error: '',
    };
  }
};

const handleUploadStart = () => {
  headerData.value = {
    ...headerData.value,
    media: {
      ...headerData.value.media,
      uploading: true,
    },
    error: '',
  };
};

const handleUploadError = errorMessage => {
  headerData.value = {
    ...headerData.value,
    media: {
      ...headerData.value.media,
      uploading: false,
    },
    error: errorMessage,
  };
};

const handleMediaUpload = mediaData => {
  if (mediaData) {
    headerData.value = {
      ...headerData.value,
      media: {
        blobId: mediaData.blobId,
        blobKey: mediaData.blobKey,
        fileUrl: mediaData.fileUrl,
        fileName: mediaData.fileName,
        contentType: mediaData.contentType,
        uploading: false,
      },
      error: '',
    };
  } else {
    headerData.value = {
      ...headerData.value,
      media: {},
      error: '',
    };
  }
};
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
            v-for="format in headerFormats"
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
      <div v-if="MEDIA_FORMATS.includes(headerData.format)" class="space-y-4">
        <FileUpload
          :model-value="headerData.media"
          :accept="getUploadConfig.accept"
          :format="headerData.format"
          :label="t('SETTINGS.TEMPLATES.BUILDER.HEADER.MEDIA_UPLOAD')"
          :uploading="!!headerData.media?.uploading"
          :error="headerData.error"
          @update:model-value="handleMediaUpload"
          @upload-start="handleUploadStart"
          @upload-error="handleUploadError"
        />
        <div
          v-if="headerData.error"
          class="bg-red-50 border border-red-200 rounded-lg p-3"
        >
          <div class="flex items-center gap-2 text-sm text-red-600">
            <span class="i-lucide-alert-circle size-4" />
            <span>{{ headerData.error }}</span>
          </div>
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
