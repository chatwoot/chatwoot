<script setup>
import { reactive, computed, ref } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, url } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { formatBytes } from 'shared/helpers/FileHelper';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import FileUpload from 'dashboard/components-next/fileUpload/FileUpload.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const emit = defineEmits(['submit', 'cancel']);
const { t } = useI18n();

// Constants
const SOURCE_TYPE = {
  URL: 'url',
  PDF: 'pdf',
};

const MESSAGE_TYPE = {
  ERROR: 'error',
  INFO: 'info',
};

const DOCUMENT_TYPE = {
  URL: 'url',
  PDF: 'pdf',
};

const FIELD_NAME = {
  URL: 'url',
  ASSISTANT_ID: 'assistantId',
};

const FILE_ACCEPT_TYPE = 'application/pdf';
const MAX_FILE_SIZE_MB = 25;

const formState = {
  uiFlags: useMapGetter('captainDocuments/getUIFlags'),
  assistants: useMapGetter('captainAssistants/getRecords'),
};

const initialState = {
  url: '',
  assistantId: null,
  selectedFile: null,
  sourceType: SOURCE_TYPE.URL,
};

const state = reactive({ ...initialState });
const uploadError = ref('');

const validationRules = computed(() => {
  const rules = {
    assistantId: { required },
  };

  if (state.sourceType === SOURCE_TYPE.URL) {
    rules.url = { required, url, minLength: minLength(1) };
  }

  return rules;
});

const assistantList = computed(() =>
  formState.assistants.value.map(assistant => ({
    value: assistant.id,
    label: assistant.name,
  }))
);

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const formattedFileSize = computed(() => {
  if (!state.selectedFile) return '';
  return formatBytes(state.selectedFile.size);
});

const getErrorMessage = (field, errorMessage) => {
  return v$.value[field]?.$error ? errorMessage : '';
};

const formErrors = computed(() => ({
  url: getErrorMessage(
    FIELD_NAME.URL,
    t('CAPTAIN.DOCUMENTS.CREATE.FORM.URL.ERROR')
  ),
  assistantId: getErrorMessage(
    FIELD_NAME.ASSISTANT_ID,
    t('CAPTAIN.DOCUMENTS.CREATE.FORM.ASSISTANT.ERROR')
  ),
}));

const handleCancel = () => emit('cancel');

const prepareDocumentDetails = () => {
  if (state.sourceType === SOURCE_TYPE.PDF) {
    return {
      type: DOCUMENT_TYPE.PDF,
      pdf_document: state.selectedFile,
      assistant_id: state.assistantId,
    };
  }

  return {
    type: DOCUMENT_TYPE.URL,
    external_link: state.url,
    assistant_id: state.assistantId,
  };
};

const handleSubmit = async () => {
  uploadError.value = '';

  // Validate form
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  // For PDF uploads, check if file is selected
  if (state.sourceType === SOURCE_TYPE.PDF && !state.selectedFile) {
    uploadError.value = t('CAPTAIN.DOCUMENTS.CREATE.FORM.PDF_UPLOAD.ERROR');
    return;
  }

  emit('submit', prepareDocumentDetails());
};

// PDF Upload handlers
const handleFileSelected = file => {
  state.selectedFile = file;
  uploadError.value = '';
};

const handleFileError = error => {
  uploadError.value = error;
  state.selectedFile = null;
};

const clearSelectedFile = () => {
  state.selectedFile = null;
  uploadError.value = '';
};

const handleSourceTypeChange = type => {
  state.sourceType = type;
  uploadError.value = '';
  state.selectedFile = null;
  state.url = '';
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <!-- Source Type Selection -->
    <div class="flex flex-col gap-2">
      <label class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ $t('CAPTAIN.DOCUMENTS.CREATE.FORM.SOURCE_TYPE.LABEL') }}
      </label>
      <div class="flex gap-2">
        <button
          type="button"
          class="flex-1 p-3 rounded-lg bg-n-alpha-2 hover:border-n-slate-7 transition-colors focus:outline-none"
          :class="{
            'ring-2 ring-n-brand text-n-brand border-0':
              state.sourceType === SOURCE_TYPE.URL,
            'border-2 border-n-slate-7 text-n-slate-11':
              state.sourceType !== SOURCE_TYPE.URL,
          }"
          @click="handleSourceTypeChange(SOURCE_TYPE.URL)"
        >
          <div class="flex items-center justify-center gap-2">
            <Icon icon="i-lucide-link" class="size-5" />
            <span class="text-sm font-medium">{{
              $t('CAPTAIN.DOCUMENTS.CREATE.FORM.SOURCE_TYPE.WEBSITE_URL')
            }}</span>
          </div>
        </button>
        <button
          type="button"
          class="flex-1 p-3 rounded-lg bg-n-alpha-2 hover:border-n-slate-7 transition-colors focus:outline-none"
          :class="{
            'ring-2 ring-n-brand text-n-brand border-0':
              state.sourceType === SOURCE_TYPE.PDF,
            'border-2 border-n-slate-7 text-n-slate-11':
              state.sourceType !== SOURCE_TYPE.PDF,
          }"
          @click="handleSourceTypeChange(SOURCE_TYPE.PDF)"
        >
          <div class="flex items-center justify-center gap-2">
            <Icon icon="i-lucide-file" class="size-5" />
            <span class="text-sm font-medium">{{
              $t('CAPTAIN.DOCUMENTS.CREATE.FORM.SOURCE_TYPE.PDF_UPLOAD')
            }}</span>
          </div>
        </button>
      </div>
    </div>

    <!-- URL Input (when URL is selected) -->
    <div v-if="state.sourceType === SOURCE_TYPE.URL">
      <Input
        v-model="state.url"
        :label="t('CAPTAIN.DOCUMENTS.CREATE.FORM.URL.LABEL')"
        :placeholder="t('CAPTAIN.DOCUMENTS.CREATE.FORM.URL.PLACEHOLDER')"
        :message="formErrors.url"
        :message-type="formErrors.url ? MESSAGE_TYPE.ERROR : MESSAGE_TYPE.INFO"
      />
    </div>

    <!-- PDF Upload (when PDF is selected) -->
    <div
      v-if="state.sourceType === SOURCE_TYPE.PDF"
      class="flex flex-col gap-2"
    >
      <label class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ $t('CAPTAIN.DOCUMENTS.CREATE.FORM.PDF_UPLOAD.LABEL') }}
      </label>

      <!-- File upload area -->
      <div v-if="!state.selectedFile">
        <FileUpload
          :accept="FILE_ACCEPT_TYPE"
          :max-size-m-b="MAX_FILE_SIZE_MB"
          :placeholder="
            t('CAPTAIN.DOCUMENTS.CREATE.FORM.PDF_UPLOAD.PLACEHOLDER')
          "
          :upload-text="
            t('CAPTAIN.DOCUMENTS.CREATE.FORM.PDF_UPLOAD.UPLOAD_TEXT')
          "
          :drag-text="t('CAPTAIN.DOCUMENTS.CREATE.FORM.PDF_UPLOAD.DROP_TEXT')"
          @file-selected="handleFileSelected"
          @file-error="handleFileError"
        />
      </div>

      <!-- Selected file display -->
      <div v-else class="p-3 bg-n-alpha-2 rounded-lg border border-n-slate-6">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <Icon icon="i-lucide-file" class="size-5 text-n-ruby-9" />
            <div>
              <p class="text-sm font-medium text-n-slate-12">
                {{ state.selectedFile.name }}
              </p>
              <p class="text-xs text-n-slate-8">
                {{ formattedFileSize }}
              </p>
            </div>
          </div>
          <button
            type="button"
            class="p-1 rounded hover:bg-n-alpha-3 text-n-slate-8 hover:text-n-slate-10"
            @click="clearSelectedFile"
          >
            <Icon icon="i-lucide-x" class="size-4" />
          </button>
        </div>
      </div>

      <!-- Upload error -->
      <p v-if="uploadError" class="text-sm text-n-ruby-9">{{ uploadError }}</p>
    </div>

    <!-- Assistant Selection -->
    <div class="flex flex-col gap-1">
      <label for="assistant" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ $t('CAPTAIN.DOCUMENTS.CREATE.FORM.ASSISTANT.LABEL') }}
      </label>
      <ComboBox
        id="assistant"
        v-model="state.assistantId"
        :options="assistantList"
        :has-error="!!formErrors.assistantId"
        :placeholder="t('CAPTAIN.DOCUMENTS.CREATE.FORM.ASSISTANT.PLACEHOLDER')"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
        :message="formErrors.assistantId"
      />
    </div>

    <!-- Action Buttons -->
    <div class="flex items-center justify-between w-full gap-3">
      <Button
        type="button"
        variant="faded"
        color="slate"
        :label="t('CAPTAIN.DOCUMENTS.CREATE.FORM.ACTIONS.CANCEL')"
        class="w-full bg-n-alpha-2 text-n-blue-11 hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        type="submit"
        :label="t('CAPTAIN.DOCUMENTS.CREATE.FORM.ACTIONS.CREATE')"
        class="w-full"
        :is-loading="isLoading"
        :disabled="isLoading"
      />
    </div>
  </form>
</template>
