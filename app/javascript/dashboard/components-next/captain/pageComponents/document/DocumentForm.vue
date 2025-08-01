<script setup>
import { reactive, computed, ref, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, url } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainDocuments/getUIFlags'),
};

const props = defineProps({
  initialName: { type: String, default: '' },
  initialDescription: { type: String, default: '' },
  initialType: { type: String, default: null },
  initialUrl: { type: String, default: '' },
  isEdit: { type: Boolean, default: false },
});

const initialState = {
  filename: '',
  url: '',
  file: null,
  type: null, // null, 'web_url', 'file', or 'text'
  text: '', // Add text for 'Text' type
  status: 'pending',
  created_at: null,
  updated_at: null,
  customer_id: null,
  location: '',
  description: '',
};

const state = reactive({ ...initialState });
const fileInput = ref(null);
const filenameManuallyEdited = ref(false);

const validationRules = computed(() => ({
  filename: { required, minLength: minLength(1) },
  type: { required },
  description: { required, minLength: minLength(1) },
  url: state.type === 'web_url' ? { required, url, minLength: minLength(1) } : {},
  text: state.type === 'text' ? { required, minLength: minLength(1) } : {},
}));

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`CAPTAIN.DOCUMENTS.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  url: getErrorMessage('url', 'URL'),
  filename: getErrorMessage('filename', 'NAME'),
  text: getErrorMessage('text', 'TEXT'),
}));

const handleCancel = () => emit('cancel');

const clearFile = () => {
  state.file = null;
  state.type = null;
  if (fileInput.value) {
    fileInput.value.value = '';
  }
  filenameManuallyEdited.value = false;
};

const clearUrl = () => {
  state.url = '';
  state.type = null;
};

const clearText = () => {
  state.text = '';
  state.type = null;
};

const MAX_FILE_SIZE = 16 * 1024 * 1024; // 16MB in bytes

const handleFileSelect = (event) => {
  const file = event.target.files?.[0] || event.dataTransfer?.files?.[0];
  console.log('[handleFileSelect] file:', file, 'instanceof File:', file instanceof File);
  if (file) {
    if (file.size > MAX_FILE_SIZE) {
      alert(t('CAPTAIN.DOCUMENTS.FORM.FILE.SIZE_ERROR'));
      clearFile();
      return;
    }

    if (file.type === 'application/pdf' || file.type === 'text/plain') {
      state.file = file;
      state.type = 'file';
      state.url = '';
      if (!filenameManuallyEdited.value && (!state.filename || state.filename.trim() === '')) {
        state.filename = file.name.replace(/\.[^/.]+$/, ''); // Remove extension
      }
    } else {
      // Show error for invalid file type
      alert(t('CAPTAIN.DOCUMENTS.FORM.FILE.INVALID_TYPE'));
    }
  }
};

const handleUrlInput = (value) => {
  if (value) {
    clearFile();
    state.type = 'web_url';
  }
};

// Add helper function for filename extension
function getFilenameWithExtension(filename, file) {
  let fileExtension = '';
  if (file && file.name && file.name.includes('.')) {
    fileExtension = file.name.substring(file.name.lastIndexOf('.'));
  }
  if (fileExtension && !filename.toLowerCase().endsWith(fileExtension.toLowerCase())) {
    return filename + fileExtension;
  }
  return filename;
}

const prepareDocumentDetails = () => {
  if (state.type === 'file') {
    // Debug log to check file type and edit mode
    console.log('[prepareDocumentDetails] isEdit:', props.isEdit, 'state.file:', state.file, 'instanceof File:', state.file instanceof File);
    if (!props.isEdit && state.file && typeof File !== 'undefined' && state.file instanceof File) {
      const formData = new FormData();
      formData.append('type', 'file');
      formData.append('description', state.description || '');
      const filenameWithExt = getFilenameWithExtension(state.filename, state.file);
      formData.append('file', state.file, filenameWithExt);
      formData.append('filename', filenameWithExt);
      return formData;
    }
    // If editing, use JSON object (no file upload)
    const filenameWithExt = getFilenameWithExtension(state.filename, state.file);
    return {
      type: 'file',
      description: state.description || '',
      name: filenameWithExt,
    };
  }
  if (state.type === 'web_url') {
    return {
      type: 'web_url',
      web_url: state.url,
      description: state.description || '',
      name: state.filename || 'Untitled Document',
    };
  }
  if (state.type === 'text') {
    return {
      type: 'text',
      raw_text: state.text,
      description: state.description || '',
      name: state.filename || 'Untitled Document',
    };
  }
  return {};
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }
  const newDocument = prepareDocumentDetails();
  // Debug logging for payload
  console.log('[DocumentForm] Submitting payload:', newDocument instanceof FormData ? Object.fromEntries(newDocument.entries()) : newDocument);
  emit('submit', newDocument);
};

const prefill = () => {
  if (props.initialName && (!state.filename || state.filename.trim() === '')) state.filename = props.initialName;
  if (props.initialDescription) state.description = props.initialDescription;
  if (props.initialType) state.type = props.initialType;
  if (props.initialUrl) state.url = props.initialUrl;
  // Only set state.file for edit mode, not for create mode
  if (props.isEdit && props.initialType === 'file') {
    state.file = { name: props.initialName };
  } else if (!props.isEdit) {
    state.file = null;
  }
};

onMounted(prefill);
watch(() => [props.initialName, props.initialDescription, props.initialType, props.initialUrl], prefill);
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
      <!-- Type Selector Dropdown -->
      <div class="flex flex-col gap-2">
        <label for="document-type" class="text-sm font-medium text-n-slate-11">{{ t('CAPTAIN.DOCUMENTS.FORM.TYPE.LABEL')}}</label>
        <div class="relative">
          <select
            id="document-type"
            name="document-type"
            v-model="state.type"
            class="border rounded px-3 py-2 text-base focus:outline-none focus:ring-2 focus:ring-n-blue-6 pr-10 w-full"
            :disabled="isLoading || isEdit"
            required
          >
            <option :value="null" disabled>{{ t('CAPTAIN.DOCUMENTS.FORM.TYPE.PLACEHOLDER')}}</option>
            <option value="file">{{ t('CAPTAIN.DOCUMENTS.FORM.TYPE.FILE')}}</option>
            <option value="web_url">{{ t('CAPTAIN.DOCUMENTS.FORM.TYPE.URL')}}</option>
            <option value="text">{{ t('CAPTAIN.DOCUMENTS.FORM.TYPE.TEXT') || 'Text' }}</option>
          </select>
        </div>
      </div>
      <!-- Name Input -->
      <Input
        id="document-name"
        name="document-name"
        v-model="state.filename"
        :label="t('CAPTAIN.DOCUMENTS.FORM.NAME.LABEL')"
        :placeholder="t('CAPTAIN.DOCUMENTS.FORM.NAME.PLACEHOLDER')"
        :message="formErrors.filename"
        :message-type="formErrors.filename ? 'error' : 'info'"
        @input="filenameManuallyEdited.value = true"
      />
      <!-- Description Input -->
      <Input
        id="document-description"
        name="document-description"
        v-model="state.description"
        :label="t('CAPTAIN.DOCUMENTS.FORM.DESCRIPTION.LABEL') || 'Description'"
        :placeholder="t('CAPTAIN.DOCUMENTS.FORM.DESCRIPTION.PLACEHOLDER') || 'Enter a description for the document'"
      />
      <!-- URL Input -->
      <div v-if="state.type === 'web_url'" class="flex flex-col gap-4">
        <div class="flex flex-col gap-1">
          <div class="relative">
            <Input
              id="document-url"
              name="document-url"
              v-model="state.url"
              :label="t('CAPTAIN.DOCUMENTS.FORM.URL.LABEL')"
              :placeholder="t('CAPTAIN.DOCUMENTS.FORM.URL.PLACEHOLDER')"
              :message="formErrors.url"
              :message-type="formErrors.url ? 'error' : 'info'"
              :disabled="state.type === 'file' || state.type === 'text'"
              @update:model-value="handleUrlInput"
            />
            <button
              v-if="state.url"
              type="button"
              class="absolute right-2 top-[34px] p-1 rounded hover:bg-n-slate-3"
              @click="clearUrl"
            >
              <Icon icon="i-lucide-x" class="text-n-slate-11" />
            </button>
          </div>
        </div>
      </div>
      <!-- File Upload -->
      <div v-if="state.type === 'file'" class="flex flex-col gap-2">
        <div
          v-if="props.isEdit"
          class="border-2 border-solid border-n-slate-6 rounded-lg p-4 text-center bg-n-alpha-2 cursor-not-allowed"
        >
          <div class="flex flex-col items-center gap-2">
            <span class="text-sm font-medium text-n-slate-11">{{ t('CAPTAIN.DOCUMENTS.FORM.FILE.UPLOADED_LABEL') || 'Uploaded File' }}</span>
            <p class="text-base text-n-slate-12">{{ state.filename }}</p>
          </div>
        </div>
        <div
          v-else
          class="border-2 border-dashed border-n-slate-6 rounded-lg p-4 text-center cursor-pointer hover:border-n-slate-8"
          @click="fileInput.click()"
          @drop.prevent="handleFileSelect($event)"
          @dragover.prevent
        >
          <input
            type="file"
            accept=".pdf,.txt"
            class="hidden"
            ref="fileInput"
            @change="handleFileSelect"
          />
          <template v-if="!state.file">
            <p class="text-n-slate-11 mb-2">
              {{ t('CAPTAIN.DOCUMENTS.FORM.FILE.DROPZONE') }}
            </p>
            <p class="text-n-slate-10 text-sm">
              {{ t('CAPTAIN.DOCUMENTS.FORM.FILE.SIZE_LIMIT') }}
            </p>
          </template>
          <div v-else class="flex items-center justify-center gap-2">
            <p class="text-sm">{{ state.file.name }}</p>
            <button
              type="button"
              class="p-1 rounded hover:bg-n-slate-3"
              @click.stop="clearFile"
            >
              <Icon icon="i-lucide-x" class="text-n-slate-11" />
            </button>
          </div>
        </div>
      </div>
      <!-- Text Input -->
      <div v-if="state.type === 'text'" class="flex flex-col gap-2">
        <label for="document-text" class="text-sm font-medium text-n-slate-11">{{ t('CAPTAIN.DOCUMENTS.FORM.TEXT.LABEL') || 'Text Content' }}</label>
        <textarea
          id="document-text"
          name="document-text"
          v-model="state.text"
          class="border rounded px-3 py-2 text-base focus:outline-none focus:ring-2 focus:ring-n-blue-6 w-full min-h-[120px]"
          :placeholder="t('CAPTAIN.DOCUMENTS.FORM.TEXT.PLACEHOLDER') || 'Enter document text here'"
          :disabled="isLoading"
        />
      </div>
      <div class="flex items-center justify-between w-full gap-3 mt-6">
        <Button
          type="button"
          variant="faded"
          color="slate"
          :label="t('CAPTAIN.FORM.CANCEL')"
          class="w-full bg-n-alpha-2 n-blue-text hover:bg-n-alpha-3"
          @click="handleCancel"
        />
        <Button
          type="submit"
          :label="isEdit ? t('CAPTAIN.FORM.EDIT') || 'Confirm' : t('CAPTAIN.FORM.CREATE')"
          class="w-full"
          :is-loading="isLoading"
          :disabled="isLoading"
        />
      </div>
    </form>
    <pre>{{ JSON.stringify(datasources, null, 2) }}</pre>
</template>

<style>
/* Ensure the toast/snackbar always appears above dialogs and modals */
.toast-fade,
.snackbar-container,
.z-toast {
  z-index: 11000 !important;
}
</style>
