<script setup>
import { reactive, computed, ref } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, url } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import FileUpload from 'dashboard/components-next/fileUpload/FileUpload.vue';

const emit = defineEmits(['submit', 'cancel']);

const formState = {
  uiFlags: useMapGetter('captainDocuments/getUIFlags'),
  assistants: useMapGetter('captainAssistants/getRecords'),
};

const initialState = {
  url: '',
  assistantId: null,
  selectedFile: null,
  sourceType: 'url', // 'url' or 'pdf'
};

const state = reactive({ ...initialState });
const uploadError = ref('');

const validationRules = computed(() => {
  const rules = {
    assistantId: { required },
  };

  if (state.sourceType === 'url') {
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

const getErrorMessage = (field, errorMessage) => {
  return v$.value[field]?.$error ? errorMessage : '';
};

const formErrors = computed(() => ({
  url: getErrorMessage('url', 'Please enter a valid URL'),
  assistantId: getErrorMessage('assistantId', 'Please select an assistant'),
}));

const handleCancel = () => emit('cancel');

const prepareDocumentDetails = () => {
  if (state.sourceType === 'pdf') {
    return {
      type: 'pdf',
      pdf_document: state.selectedFile,
      assistant_id: state.assistantId,
    };
  }

  return {
    type: 'url',
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
  if (state.sourceType === 'pdf' && !state.selectedFile) {
    uploadError.value = 'Please select a PDF file to upload.';
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
            'ring-2 ring-woot-500 text-woot-500 border-0':
              state.sourceType === 'url',
            'border-2 border-n-slate-7 text-n-slate-11':
              state.sourceType !== 'url',
          }"
          @click="handleSourceTypeChange('url')"
        >
          <div class="flex items-center justify-center gap-2">
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M3.9 12C3.9 10.29 5.29 8.9 7 8.9H11V7H7C4.24 7 2 9.24 2 12S4.24 17 7 17H11V15.1H7C5.29 15.1 3.9 13.71 3.9 12ZM8 13H16V11H8V13ZM17 7H13V8.9H17C18.71 8.9 20.1 10.29 20.1 12S18.71 15.1 17 15.1H13V17H17C19.76 17 22 14.76 22 12S19.76 7 17 7Z"
                fill="currentColor"
              />
            </svg>
            <span class="text-sm font-medium">{{
              $t('CAPTAIN.DOCUMENTS.CREATE.FORM.SOURCE_TYPE.WEBSITE_URL')
            }}</span>
          </div>
        </button>
        <button
          type="button"
          class="flex-1 p-3 rounded-lg bg-n-alpha-2 hover:border-n-slate-7 transition-colors focus:outline-none"
          :class="{
            'ring-2 ring-woot-500 text-woot-500 border-0':
              state.sourceType === 'pdf',
            'border-2 border-n-slate-7 text-n-slate-11':
              state.sourceType !== 'pdf',
          }"
          @click="handleSourceTypeChange('pdf')"
        >
          <div class="flex items-center justify-center gap-2">
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M14,2H6A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2M18,20H6V4H13V9H18V20Z"
                fill="currentColor"
              />
            </svg>
            <span class="text-sm font-medium">{{
              $t('CAPTAIN.DOCUMENTS.CREATE.FORM.SOURCE_TYPE.PDF_UPLOAD')
            }}</span>
          </div>
        </button>
      </div>
    </div>

    <!-- URL Input (when URL is selected) -->
    <div v-if="state.sourceType === 'url'">
      <Input
        v-model="state.url"
        label="Website URL"
        placeholder="Enter the website URL to crawl"
        :message="formErrors.url"
        :message-type="formErrors.url ? 'error' : 'info'"
      />
    </div>

    <!-- PDF Upload (when PDF is selected) -->
    <div v-if="state.sourceType === 'pdf'" class="flex flex-col gap-2">
      <label class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ $t('CAPTAIN.DOCUMENTS.CREATE.FORM.PDF_UPLOAD.LABEL') }}
      </label>

      <!-- File upload area -->
      <div v-if="!state.selectedFile">
        <FileUpload
          accept="application/pdf"
          :max-size-m-b="25"
          placeholder="Select a PDF file"
          upload-text="Click to select PDF or drag and drop"
          drag-text="Drop PDF file here"
          @file-selected="handleFileSelected"
          @file-error="handleFileError"
        />
      </div>

      <!-- Selected file display -->
      <div v-else class="p-3 bg-n-alpha-2 rounded-lg border border-n-slate-6">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              class="text-red-600"
            >
              <path
                d="M14,2H6A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2M18,20H6V4H13V9H18V20Z"
                fill="currentColor"
              />
            </svg>
            <div>
              <p class="text-sm font-medium text-n-slate-12">
                {{ state.selectedFile.name }}
              </p>
              <p class="text-xs text-n-slate-8">
                {{
                  Math.round((state.selectedFile.size / 1024 / 1024) * 100) /
                  100
                }}
                {{ $t('GENERAL.FILE_SIZE.MB') }}
              </p>
            </div>
          </div>
          <button
            type="button"
            class="p-1 rounded hover:bg-n-alpha-3 text-n-slate-8 hover:text-n-slate-10"
            @click="clearSelectedFile"
          >
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z"
                fill="currentColor"
              />
            </svg>
          </button>
        </div>
      </div>

      <!-- Upload error -->
      <p v-if="uploadError" class="text-sm text-red-600">{{ uploadError }}</p>
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
        placeholder="Choose an assistant"
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
        label="Cancel"
        class="w-full bg-n-alpha-2 n-blue-text hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        type="submit"
        label="Create Document"
        class="w-full"
        :is-loading="isLoading"
        :disabled="isLoading"
      />
    </div>
  </form>
</template>
