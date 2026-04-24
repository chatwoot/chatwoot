<script setup>
/**
 * This component handles parsing and sending WhatsApp message templates.
 * It works as follows:
 * 1. Displays the template text with variable placeholders.
 * 2. Generates input fields for each variable in the template.
 * 3. Validates that all variables are filled before sending.
 * 4. Replaces placeholders with user-provided values.
 * 5. Emits events to send the processed message or reset the template.
 */
import { ref, computed, onMounted, watch } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { requiredIf } from '@vuelidate/validators';
import { useI18n } from 'vue-i18n';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import {
  buildTemplateParameters,
  allKeysRequired,
  replaceTemplateVariables,
  DEFAULT_LANGUAGE,
  DEFAULT_CATEGORY,
  COMPONENT_TYPES,
  MEDIA_FORMATS,
  findComponentByType,
} from 'dashboard/helper/templateHelper';

const props = defineProps({
  template: {
    type: Object,
    default: () => ({}),
    validator: value => {
      if (!value || typeof value !== 'object') return false;
      if (!value.components || !Array.isArray(value.components)) return false;
      return true;
    },
  },
});

const emit = defineEmits(['sendMessage', 'resetTemplate', 'back']);

const { t } = useI18n();

const processedParams = ref({});
const isUploadingMedia = ref(false);
const mediaUploadError = ref('');
const mediaPreview = ref(null);
const mediaInputRef = ref(null);
const isDragOverMediaZone = ref(false);

const languageLabel = computed(() => {
  return `${t('WHATSAPP_TEMPLATES.PARSER.LANGUAGE')}: ${props.template.language || DEFAULT_LANGUAGE}`;
});

const categoryLabel = computed(() => {
  return `${t('WHATSAPP_TEMPLATES.PARSER.CATEGORY')}: ${props.template.category || DEFAULT_CATEGORY}`;
});

const headerComponent = computed(() => {
  return findComponentByType(props.template, COMPONENT_TYPES.HEADER);
});

const bodyComponent = computed(() => {
  return findComponentByType(props.template, COMPONENT_TYPES.BODY);
});

const bodyText = computed(() => {
  return bodyComponent.value?.text || '';
});

const hasMediaHeader = computed(() =>
  MEDIA_FORMATS.includes(headerComponent.value?.format)
);

const formatType = computed(() => {
  const format = headerComponent.value?.format;
  return format ? format.charAt(0) + format.slice(1).toLowerCase() : '';
});

const isDocumentTemplate = computed(() => {
  return headerComponent.value?.format?.toLowerCase() === 'document';
});

const hasVariables = computed(() => {
  return bodyText.value?.match(/{{([^}]+)}}/g) !== null;
});

const renderedTemplate = computed(() => {
  return replaceTemplateVariables(bodyText.value, processedParams.value);
});

const isFormInvalid = computed(() => {
  if (!hasVariables.value && !hasMediaHeader.value) return false;

  if (hasMediaHeader.value && isUploadingMedia.value) {
    return true;
  }

  const hasMediaReference =
    processedParams.value.header?.media_url ||
    processedParams.value.header?.media_blob_id;

  if (hasMediaHeader.value && !hasMediaReference) {
    return true;
  }

  if (hasVariables.value && processedParams.value.body) {
    const hasEmptyBodyVariable = Object.values(processedParams.value.body).some(
      value => !value
    );
    if (hasEmptyBodyVariable) return true;
  }

  if (processedParams.value.buttons) {
    const hasEmptyButtonParameter = processedParams.value.buttons.some(
      button => !button.parameter
    );
    if (hasEmptyButtonParameter) return true;
  }

  return false;
});

const v$ = useVuelidate(
  {
    processedParams: {
      requiredIfKeysPresent: requiredIf(hasVariables),
      allKeysRequired,
    },
  },
  { processedParams }
);

const initializeTemplateParameters = () => {
  processedParams.value = buildTemplateParameters(
    props.template,
    hasMediaHeader.value
  );
};

function clearMediaPreview() {
  if (mediaPreview.value?.url) {
    URL.revokeObjectURL(mediaPreview.value.url);
  }
  mediaPreview.value = null;
}

const updateMediaUrl = value => {
  processedParams.value.header ??= {};
  processedParams.value.header.media_url = value;
  if (value) {
    processedParams.value.header.media_blob_id = '';
    mediaUploadError.value = '';
    clearMediaPreview();
  }
};

const updateMediaName = value => {
  processedParams.value.header ??= {};
  processedParams.value.header.media_name = value;
};

const allowedMimeTypes = computed(() => {
  const mediaType = headerComponent.value?.format?.toLowerCase();
  if (mediaType === 'image') return ['image/*'];
  if (mediaType === 'video') return ['video/*'];
  if (mediaType === 'document') {
    return [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/plain',
    ];
  }
  return ['*/*'];
});

const localFileAccept = computed(() => allowedMimeTypes.value.join(','));

const isAllowedFileType = file => {
  const mediaType = headerComponent.value?.format?.toLowerCase();
  if (mediaType === 'image') return file.type.startsWith('image/');
  if (mediaType === 'video') return file.type.startsWith('video/');
  if (mediaType === 'document')
    return allowedMimeTypes.value.includes(file.type);
  return false;
};

const updateMediaPreview = file => {
  clearMediaPreview();

  const isImage = file.type.startsWith('image/');
  mediaPreview.value = {
    name: file.name,
    size: file.size,
    type: file.type,
    url: isImage ? URL.createObjectURL(file) : '',
    isImage,
  };
};

const clearUploadedMedia = () => {
  processedParams.value.header ??= {};
  processedParams.value.header.media_blob_id = '';
  processedParams.value.header.media_url = '';
  mediaUploadError.value = '';
  clearMediaPreview();
};

const processUploadedFile = async file => {
  if (!file) return;

  processedParams.value.header ??= {};
  mediaUploadError.value = '';

  if (!isAllowedFileType(file)) {
    mediaUploadError.value = t('WHATSAPP_TEMPLATES.PARSER.INVALID_MEDIA_TYPE');
    return;
  }

  // Drop previous media immediately so send cannot use stale blob/URL while the new upload resolves.
  processedParams.value.header.media_blob_id = '';
  processedParams.value.header.media_url = '';
  isUploadingMedia.value = true;
  updateMediaPreview(file);
  try {
    const { blobId } = await uploadFile(file);
    processedParams.value.header.media_blob_id = blobId;
    processedParams.value.header.media_url = '';
    if (isDocumentTemplate.value && !processedParams.value.header.media_name) {
      processedParams.value.header.media_name = file.name;
    }
  } catch (error) {
    mediaUploadError.value =
      error?.response?.data?.error ||
      t('WHATSAPP_TEMPLATES.PARSER.MEDIA_UPLOAD_FAILED');
  } finally {
    isUploadingMedia.value = false;
  }
};

const handleMediaUpload = async event => {
  const file = event?.target?.files?.[0];
  await processUploadedFile(file);
  event.target.value = '';
};

const openFilePicker = () => {
  mediaInputRef.value?.click();
};

const onMediaDragOver = event => {
  event.preventDefault();
  if (isUploadingMedia.value) return;
  isDragOverMediaZone.value = true;
};

const onMediaDragLeave = () => {
  isDragOverMediaZone.value = false;
};

const onMediaDrop = async event => {
  event.preventDefault();
  if (isUploadingMedia.value) return;
  isDragOverMediaZone.value = false;
  const file = event?.dataTransfer?.files?.[0];
  await processUploadedFile(file);
};

const mediaPreviewSize = computed(() => {
  if (!mediaPreview.value?.size) return '';
  return `${Math.ceil(mediaPreview.value.size / 1024)} KB`;
});

const sendMessage = () => {
  if (isUploadingMedia.value) return;
  v$.value.$touch();
  if (v$.value.$invalid) return;

  const { name, category, language, namespace } = props.template;

  const payload = {
    message: renderedTemplate.value,
    templateParams: {
      name,
      category,
      language,
      namespace,
      processed_params: processedParams.value,
    },
  };
  emit('sendMessage', payload);
};

const resetTemplate = () => {
  emit('resetTemplate');
};

const goBack = () => {
  emit('back');
};

onMounted(initializeTemplateParameters);

watch(
  () => props.template,
  () => {
    initializeTemplateParameters();
    clearMediaPreview();
    mediaUploadError.value = '';
    v$.value.$reset();
  },
  { deep: true }
);

watch(
  () => processedParams.value.header?.media_url,
  value => {
    if (value) {
      clearMediaPreview();
    }
  }
);

defineExpose({
  processedParams,
  hasVariables,
  hasMediaHeader,
  isDocumentTemplate,
  headerComponent,
  renderedTemplate,
  v$,
  updateMediaUrl,
  updateMediaName,
  sendMessage,
  resetTemplate,
  goBack,
});
</script>

<template>
  <div>
    <div class="flex flex-col gap-4 p-4 mb-4 rounded-lg bg-n-alpha-black2">
      <div class="flex justify-between items-center">
        <h3 class="text-sm font-medium text-n-slate-12">
          {{ template.name }}
        </h3>
        <span class="text-xs text-n-slate-11">
          {{ languageLabel }}
        </span>
      </div>

      <div class="flex flex-col gap-2">
        <div class="rounded-md">
          <div class="text-sm whitespace-pre-wrap text-n-slate-12">
            {{ renderedTemplate }}
          </div>
        </div>
      </div>

      <div class="text-xs text-n-slate-11">
        {{ categoryLabel }}
      </div>
    </div>

    <div v-if="hasVariables || hasMediaHeader">
      <div v-if="hasMediaHeader" class="mb-4">
        <p class="mb-2.5 text-sm font-semibold">
          {{
            $t('WHATSAPP_TEMPLATES.PARSER.MEDIA_HEADER_LABEL', {
              type: formatType,
            }) || `${formatType} Header`
          }}
        </p>
        <div
          class="p-2 mb-2.5 rounded-lg border transition-colors"
          :class="
            isDragOverMediaZone
              ? 'border-n-brand bg-n-alpha-1'
              : 'border-n-strong bg-transparent'
          "
          @dragover="onMediaDragOver"
          @dragleave="onMediaDragLeave"
          @drop="onMediaDrop"
        >
          <div class="flex items-center gap-2">
            <Input
              :model-value="processedParams.header?.media_url || ''"
              type="url"
              class="flex-1"
              :placeholder="
                t('WHATSAPP_TEMPLATES.PARSER.MEDIA_URL_LABEL', {
                  type: formatType,
                })
              "
              @update:model-value="updateMediaUrl"
            />
            <Button
              icon="i-lucide-upload"
              faded
              slate
              size="sm"
              type="button"
              class="shrink-0 !w-8"
              :disabled="isUploadingMedia"
              :title="$t('WHATSAPP_TEMPLATES.PARSER.UPLOAD_LOCAL_FILE')"
              @click="openFilePicker"
            />
            <Button
              v-if="processedParams.header?.media_blob_id"
              variant="ghost"
              color="slate"
              icon="i-lucide-trash-2"
              size="xs"
              type="button"
              :title="$t('WHATSAPP_TEMPLATES.PARSER.REMOVE_UPLOADED_FILE')"
              @click="clearUploadedMedia"
            />
          </div>
          <input
            ref="mediaInputRef"
            type="file"
            class="hidden"
            :accept="localFileAccept"
            :disabled="isUploadingMedia"
            @change="handleMediaUpload"
          />
          <p class="mt-1 text-xs text-n-slate-11">
            {{ $t('WHATSAPP_TEMPLATES.PARSER.DRAG_AND_DROP_HINT') }}
          </p>
        </div>
        <div v-if="isUploadingMedia" class="mb-2.5 text-xs text-n-slate-11">
          {{ $t('WHATSAPP_TEMPLATES.PARSER.UPLOADING_MEDIA') }}
        </div>
        <div
          v-if="mediaPreview"
          class="flex items-center gap-2 p-2 mb-2.5 rounded-md border border-n-strong bg-n-alpha-black2"
        >
          <img
            v-if="mediaPreview.isImage"
            :src="mediaPreview.url"
            :alt="mediaPreview.name"
            class="object-cover w-10 h-10 rounded"
          />
          <div class="flex flex-col min-w-0">
            <span class="text-xs font-medium truncate text-n-slate-12">
              {{ mediaPreview.name }}
            </span>
            <span class="text-xs text-n-slate-11">
              {{ mediaPreviewSize }}
            </span>
          </div>
        </div>
        <p v-if="mediaUploadError" class="mb-2.5 text-xs text-n-ruby-9">
          {{ mediaUploadError }}
        </p>
        <div v-if="isDocumentTemplate" class="flex items-center mb-2.5">
          <Input
            :model-value="processedParams.header?.media_name || ''"
            type="text"
            class="flex-1"
            :placeholder="
              t('WHATSAPP_TEMPLATES.PARSER.DOCUMENT_NAME_PLACEHOLDER')
            "
            @update:model-value="updateMediaName"
          />
        </div>
      </div>

      <!-- Body Variables Section -->
      <div v-if="processedParams.body">
        <p class="mb-2.5 text-sm font-semibold">
          {{ $t('WHATSAPP_TEMPLATES.PARSER.VARIABLES_LABEL') }}
        </p>
        <div
          v-for="(variable, key) in processedParams.body"
          :key="`body-${key}`"
          class="flex items-center mb-2.5"
        >
          <Input
            v-model="processedParams.body[key]"
            type="text"
            class="flex-1"
            :placeholder="
              t('WHATSAPP_TEMPLATES.PARSER.VARIABLE_PLACEHOLDER', {
                variable: key,
              })
            "
          />
        </div>
      </div>

      <!-- Button Variables Section -->
      <div v-if="processedParams.buttons">
        <p class="mb-2.5 text-sm font-semibold">
          {{ t('WHATSAPP_TEMPLATES.PARSER.BUTTON_PARAMETERS') }}
        </p>
        <div
          v-for="(button, index) in processedParams.buttons"
          :key="`button-${index}`"
          class="flex items-center mb-2.5"
        >
          <Input
            v-model="processedParams.buttons[index].parameter"
            type="text"
            class="flex-1"
            :placeholder="t('WHATSAPP_TEMPLATES.PARSER.BUTTON_PARAMETER')"
          />
        </div>
      </div>
      <p
        v-if="v$.$dirty && v$.$invalid"
        class="p-2.5 text-center rounded-md bg-n-ruby-9/20 text-n-ruby-9"
      >
        {{ $t('WHATSAPP_TEMPLATES.PARSER.FORM_ERROR_MESSAGE') }}
      </p>
    </div>

    <slot
      name="actions"
      :send-message="sendMessage"
      :reset-template="resetTemplate"
      :go-back="goBack"
      :is-valid="!v$.$invalid"
      :disabled="isFormInvalid"
    />
  </div>
</template>
