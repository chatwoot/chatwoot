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
import Spinner from 'shared/components/Spinner.vue';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import {
  buildTemplateParameters,
  allKeysRequired,
  replaceTemplateVariables,
  DEFAULT_LANGUAGE,
  DEFAULT_CATEGORY,
  COMPONENT_TYPES,
  MEDIA_FORMATS,
  UPLOAD_CONFIG,
  findComponentByType,
} from 'dashboard/helper/templateHelper';
import WhatsAppTemplatePreview from './WhatsAppTemplatePreview.vue';

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

  if (hasMediaHeader.value && !processedParams.value.header?.media_url) {
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

const updateMediaUrl = value => {
  processedParams.value.header ??= {};
  processedParams.value.header.media_url = value;
};

const updateMediaName = value => {
  processedParams.value.header ??= {};
  processedParams.value.header.media_name = value;
};

// File upload state for media headers
const fileInputRef = ref(null);
const isUploading = ref(false);
const uploadError = ref('');
const uploadedPreview = ref(null);

const acceptTypes = computed(() => {
  const format = headerComponent.value?.format;
  return UPLOAD_CONFIG[format]?.accept || '';
});

const triggerFileUpload = () => {
  fileInputRef.value?.click();
};

const handleFileSelected = async event => {
  const file = event.target.files?.[0];
  if (!file) return;

  isUploading.value = true;
  uploadError.value = '';

  try {
    const { fileUrl } = await uploadFile(file);
    updateMediaUrl(fileUrl);
    uploadedPreview.value = {
      url: fileUrl,
      name: file.name,
      type: file.type,
    };

    if (isDocumentTemplate.value) {
      updateMediaName(file.name);
    }
  } catch {
    uploadError.value = t('WHATSAPP_TEMPLATES.PARSER.UPLOAD_ERROR');
  } finally {
    isUploading.value = false;
    if (fileInputRef.value) fileInputRef.value.value = '';
  }
};

const removeUploadedMedia = () => {
  updateMediaUrl('');
  uploadedPreview.value = null;
  uploadError.value = '';
  if (isDocumentTemplate.value) {
    updateMediaName('');
  }
};

const sendMessage = () => {
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
    v$.value.$reset();
  },
  { deep: true }
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

    <!-- Live WhatsApp preview -->
    <WhatsAppTemplatePreview
      :template="template"
      :processed-params="processedParams"
      class="mb-4"
    />

    <div v-if="hasVariables || hasMediaHeader">
      <div v-if="hasMediaHeader" class="mb-4">
        <p class="mb-2.5 text-sm font-semibold">
          {{
            $t('WHATSAPP_TEMPLATES.PARSER.MEDIA_HEADER_LABEL', {
              type: formatType,
            }) || `${formatType} Header`
          }}
        </p>

        <input
          ref="fileInputRef"
          type="file"
          :accept="acceptTypes"
          class="hidden"
          @change="handleFileSelected"
        />

        <!-- Uploaded/selected media preview -->
        <div v-if="uploadedPreview" class="mb-2.5">
          <div
            class="rounded-lg border border-n-weak overflow-hidden bg-n-solid-3"
          >
            <img
              v-if="headerComponent?.format === 'IMAGE'"
              :src="uploadedPreview.url"
              alt=""
              class="w-full max-h-36 object-cover"
            />
            <div v-else class="flex items-center gap-3 p-3">
              <span
                :class="
                  headerComponent?.format === 'VIDEO'
                    ? 'i-lucide-video'
                    : 'i-lucide-file-text'
                "
                class="size-5 text-n-slate-11"
              />
              <span class="text-sm text-n-slate-12 truncate flex-1">
                {{ uploadedPreview.name }}
              </span>
            </div>
          </div>
          <div class="flex items-center gap-2 mt-1.5">
            <Button
              :label="t('WHATSAPP_TEMPLATES.PARSER.REPLACE_MEDIA')"
              icon="i-lucide-refresh-cw"
              size="xs"
              variant="ghost"
              color="slate"
              @click="triggerFileUpload"
            />
            <Button
              :label="t('WHATSAPP_TEMPLATES.PARSER.REMOVE_MEDIA')"
              icon="i-lucide-trash-2"
              size="xs"
              variant="ghost"
              color="ruby"
              @click="removeUploadedMedia"
            />
          </div>
        </div>

        <!-- Upload button + URL input when no media selected -->
        <div v-else class="space-y-2.5">
          <div class="flex items-center gap-2">
            <Button
              :label="
                isUploading
                  ? t('WHATSAPP_TEMPLATES.PARSER.UPLOADING')
                  : t('WHATSAPP_TEMPLATES.PARSER.UPLOAD_MEDIA')
              "
              :icon="isUploading ? '' : 'i-lucide-upload'"
              size="sm"
              variant="outline"
              color="slate"
              :disabled="isUploading"
              @click="triggerFileUpload"
            >
              <template v-if="isUploading" #icon>
                <Spinner size="small" />
              </template>
            </Button>
            <span class="text-xs text-n-slate-11">
              {{ t('WHATSAPP_TEMPLATES.PARSER.OR_PASTE_URL') }}
            </span>
          </div>
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
        </div>

        <p v-if="uploadError" class="mt-1.5 text-xs text-n-ruby-11">
          {{ uploadError }}
        </p>

        <div v-if="isDocumentTemplate && !uploadedPreview" class="mt-2.5">
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
