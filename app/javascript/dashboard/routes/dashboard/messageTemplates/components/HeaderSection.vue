<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Spinner from 'shared/components/Spinner.vue';
import VariableSection from './VariableSection.vue';
import { MEDIA_FORMATS, UPLOAD_CONFIG } from 'dashboard/helper/templateHelper';
import { uploadFile } from 'dashboard/helper/uploadHelper';

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

const fileInputRef = ref(null);
const isUploading = ref(false);
const uploadError = ref('');

const headerData = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value),
});

const hasUploadedMedia = computed(() => {
  return !!headerData.value.media?.fileUrl;
});

const acceptTypes = computed(() => {
  const format = headerData.value.format;
  return UPLOAD_CONFIG[format]?.accept || '';
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
  uploadError.value = '';
  if (MEDIA_FORMATS.includes(format) || format === 'LOCATION') {
    headerData.value = {
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
  } else {
    headerData.value = {
      ...headerData.value,
      format,
      media: {},
      error: '',
    };
  }
};

const triggerFileUpload = () => {
  fileInputRef.value?.click();
};

const handleFileSelected = async event => {
  const file = event.target.files?.[0];
  if (!file) return;

  isUploading.value = true;
  uploadError.value = '';

  try {
    const { fileUrl, blobId, blobKey } = await uploadFile(file);
    headerData.value = {
      ...headerData.value,
      media: {
        fileUrl,
        blobId,
        blobKey,
        fileName: file.name,
        contentType: file.type,
      },
      error: '',
    };
  } catch {
    uploadError.value = t(
      'MESSAGE_TEMPLATES.BUILDER.HEADER.MEDIA_UPLOAD_ERROR'
    );
  } finally {
    isUploading.value = false;
    // Reset file input so the same file can be re-selected
    if (fileInputRef.value) fileInputRef.value.value = '';
  }
};

const removeMedia = () => {
  headerData.value = {
    ...headerData.value,
    media: {},
    error: '',
  };
  uploadError.value = '';
};
</script>

<template>
  <div class="bg-n-solid-2 rounded-lg p-4 border border-n-weak">
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center gap-3">
        <span class="i-lucide-layout-panel-top size-5 text-n-slate-11" />
        <h4 class="font-medium text-n-slate-12">
          {{ t('MESSAGE_TEMPLATES.BUILDER.HEADER.TITLE') }}
        </h4>
        <span class="text-xs text-n-slate-11 bg-n-solid-3 px-2 py-1 rounded">
          {{ t('MESSAGE_TEMPLATES.BUILDER.OPTIONAL') }}
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
          {{ t('MESSAGE_TEMPLATES.BUILDER.HEADER.TYPE') }}
        </label>
        <div class="flex gap-2 flex-wrap">
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

      <!-- Text header -->
      <div v-if="headerData.format === 'TEXT'">
        <VariableSection
          v-model="headerTextData"
          input-type="input"
          :max-length="60"
          :placeholder="t('MESSAGE_TEMPLATES.BUILDER.HEADER.TEXT_PLACEHOLDER')"
          :label="t('MESSAGE_TEMPLATES.BUILDER.HEADER.TEXT_LABEL')"
          :help-text="t('MESSAGE_TEMPLATES.BUILDER.HEADER.TEXT_HELP')"
          :parameter-type="parameterType"
          :max-variables="1"
        />
      </div>

      <!-- Media header upload -->
      <div v-if="MEDIA_FORMATS.includes(headerData.format)" class="space-y-4">
        <input
          ref="fileInputRef"
          type="file"
          :accept="acceptTypes"
          class="hidden"
          @change="handleFileSelected"
        />

        <!-- Uploaded file preview -->
        <div
          v-if="hasUploadedMedia"
          class="rounded-lg border border-n-weak overflow-hidden"
        >
          <!-- Image preview -->
          <img
            v-if="headerData.format === 'IMAGE'"
            :src="headerData.media.fileUrl"
            alt=""
            class="w-full max-h-48 object-cover"
          />
          <!-- Video/Document preview -->
          <div v-else class="flex items-center gap-3 p-4 bg-n-solid-3">
            <span
              :class="
                headerData.format === 'VIDEO'
                  ? 'i-lucide-video'
                  : 'i-lucide-file-text'
              "
              class="size-6 text-n-slate-11"
            />
            <span class="text-sm text-n-slate-12 truncate flex-1">
              {{ headerData.media.fileName }}
            </span>
          </div>
          <div class="flex items-center justify-end gap-2 p-2 bg-n-solid-2">
            <NextButton
              :label="t('MESSAGE_TEMPLATES.BUILDER.HEADER.MEDIA_REPLACE')"
              icon="i-lucide-refresh-cw"
              size="xs"
              variant="ghost"
              color="slate"
              @click="triggerFileUpload"
            />
            <NextButton
              :label="t('MESSAGE_TEMPLATES.BUILDER.HEADER.MEDIA_REMOVE')"
              icon="i-lucide-trash-2"
              size="xs"
              variant="ghost"
              color="ruby"
              @click="removeMedia"
            />
          </div>
        </div>

        <!-- Upload dropzone -->
        <div
          v-else-if="!isUploading"
          class="border-2 border-dashed border-n-weak rounded-lg p-6 text-center cursor-pointer hover:border-n-brand hover:bg-n-alpha-black2 transition-colors"
          @click="triggerFileUpload"
        >
          <span class="i-lucide-upload size-8 mx-auto mb-2 text-n-slate-11" />
          <p class="text-sm text-n-slate-11">
            {{ t('MESSAGE_TEMPLATES.BUILDER.HEADER.MEDIA_UPLOAD') }}
          </p>
          <p class="text-xs text-n-slate-9 mt-1">
            {{
              t('MESSAGE_TEMPLATES.BUILDER.HEADER.MEDIA_FORMAT_HINT', {
                format: headerData.format,
              })
            }}
          </p>
        </div>

        <!-- Upload progress -->
        <div
          v-else
          class="border-2 border-dashed border-n-brand rounded-lg p-6 flex flex-col items-center gap-2"
        >
          <Spinner size="small" />
          <p class="text-sm text-n-slate-11">
            {{ t('MESSAGE_TEMPLATES.BUILDER.HEADER.MEDIA_UPLOADING') }}
          </p>
        </div>

        <!-- Upload error -->
        <div
          v-if="uploadError"
          class="flex items-center gap-2 text-sm text-red-600 bg-red-50 px-3 py-2 rounded-lg"
        >
          <span class="i-lucide-alert-triangle size-4" />
          {{ uploadError }}
        </div>
      </div>

      <!-- Location header info -->
      <div v-if="headerData.format === 'LOCATION'" class="space-y-2">
        <div
          class="flex items-center gap-3 p-4 bg-n-solid-3 rounded-lg border border-n-weak"
        >
          <span class="i-lucide-map-pin size-6 text-n-slate-11" />
          <p class="text-sm text-n-slate-11">
            {{ t('MESSAGE_TEMPLATES.BUILDER.HEADER.LOCATION_HINT') }}
          </p>
        </div>
      </div>
    </div>

    <div v-else class="text-center py-8 text-n-slate-11">
      <span class="i-lucide-layout-panel-top size-12 mx-auto mb-3 opacity-50" />
      <p class="text-sm">
        {{ t('MESSAGE_TEMPLATES.BUILDER.HEADER.DISABLED_TEXT') }}
      </p>
    </div>
  </div>
</template>
