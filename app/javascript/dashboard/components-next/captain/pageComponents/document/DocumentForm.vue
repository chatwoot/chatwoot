<script setup>
import { reactive, computed, ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, requiredIf } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainDocuments/getUIFlags'),
  assistants: useMapGetter('captainAssistants/getRecords'),
};

const initialState = {
  name: '',
  url: '',
  assistantId: null,
  documentType: 'url',
  pdfFile: null,
};

const state = reactive({ ...initialState });
const fileInputRef = ref(null);

const validationRules = {
  url: {
    required: requiredIf(() => state.documentType === 'url'),
    url: requiredIf(() => state.documentType === 'url'),
    minLength: minLength(1),
  },
  assistantId: { required },
  pdfFile: {
    required: requiredIf(() => state.documentType === 'pdf'),
  },
};

const assistantList = computed(() =>
  formState.assistants.value.map(assistant => ({
    value: assistant.id,
    label: assistant.name,
  }))
);

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`CAPTAIN.DOCUMENTS.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  url: getErrorMessage('url', 'URL'),
  assistantId: getErrorMessage('assistantId', 'ASSISTANT'),
  pdfFile: getErrorMessage('pdfFile', 'PDF_FILE'),
}));

const handleCancel = () => emit('cancel');

const handleFileChange = event => {
  const file = event.target.files[0];
  if (file) {
    if (file.type !== 'application/pdf') {
      useAlert(t('CAPTAIN.DOCUMENTS.FORM.PDF_FILE.INVALID_TYPE'));
      event.target.value = '';
      return;
    }
    if (file.size > 10 * 1024 * 1024) {
      // 10MB
      useAlert(t('CAPTAIN.DOCUMENTS.FORM.PDF_FILE.TOO_LARGE'));
      event.target.value = '';
      return;
    }
    state.pdfFile = file;
    state.name = file.name.replace('.pdf', '');
  }
};

const openFileDialog = () => {
  // Use nextTick to ensure the ref is available
  nextTick(() => {
    if (fileInputRef.value) {
      fileInputRef.value.click();
    }
  });
};

const prepareDocumentDetails = () => {
  const formData = new FormData();
  formData.append('document[assistant_id]', state.assistantId);

  if (state.documentType === 'url') {
    formData.append('document[external_link]', state.url);
    formData.append('document[name]', state.name || state.url);
  } else {
    formData.append('document[pdf_file]', state.pdfFile);
    formData.append(
      'document[name]',
      state.name || state.pdfFile.name.replace('.pdf', '')
    );
    // No need to send external_link for PDF - it's auto-generated in the backend
  }

  return formData;
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', prepareDocumentDetails());
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.DOCUMENTS.FORM.TYPE.LABEL') }}
      </label>
      <div class="grid grid-cols-2 gap-3 p-1 rounded-lg bg-n-slate-3">
        <button
          type="button"
          class="flex relative gap-2 justify-center items-center px-4 py-2.5 text-sm font-medium rounded-md transition-all duration-200"
          :class="
            state.documentType === 'url'
              ? 'bg-n-white text-n-slate-12 shadow-sm'
              : 'text-n-slate-11 hover:text-n-slate-12'
          "
          @click="state.documentType = 'url'"
        >
          <i class="text-base i-ph-link-simple" />
          <span>{{ t('CAPTAIN.DOCUMENTS.FORM.TYPE.URL') }}</span>
        </button>
        <button
          type="button"
          class="flex relative gap-2 justify-center items-center px-4 py-2.5 text-sm font-medium rounded-md transition-all duration-200"
          :class="
            state.documentType === 'pdf'
              ? 'bg-n-white text-n-slate-12 shadow-sm'
              : 'text-n-slate-11 hover:text-n-slate-12'
          "
          @click="state.documentType = 'pdf'"
        >
          <i class="text-base i-ph-file-pdf" />
          <span>{{ t('CAPTAIN.DOCUMENTS.FORM.TYPE.PDF') }}</span>
        </button>
      </div>
    </div>

    <Input
      v-if="state.documentType === 'url'"
      v-model="state.url"
      :label="t('CAPTAIN.DOCUMENTS.FORM.URL.LABEL')"
      :placeholder="t('CAPTAIN.DOCUMENTS.FORM.URL.PLACEHOLDER')"
      :message="formErrors.url"
      :message-type="formErrors.url ? 'error' : 'info'"
    />

    <!-- PDF file picker should have a solid-1 background-color and border-weak boundary. Space between header and subtext should be less (maybe 6px). -->

    <div v-if="state.documentType === 'pdf'" class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.DOCUMENTS.FORM.PDF_FILE.LABEL') }}
      </label>
      <div class="relative">
        <input
          ref="fileInputRef"
          type="file"
          accept=".pdf"
          class="hidden"
          @change="handleFileChange"
        />
        <Button
          type="button"
          slate
          class="!w-full !h-auto !justify-between !py-4"
          @click="openFileDialog"
        >
          <template #default>
            <div class="flex gap-2 items-center">
              <div
                class="flex justify-center items-center w-10 h-10 rounded-lg bg-n-slate-3"
              >
                <i class="text-xl i-ph-file-pdf text-n-slate-11" />
              </div>
              <div class="flex flex-col flex-1 gap-1 items-start">
                <p class="m-0 text-sm font-medium text-n-slate-12">
                  {{
                    state.pdfFile
                      ? state.pdfFile.name
                      : t('CAPTAIN.DOCUMENTS.FORM.PDF_FILE.CHOOSE_FILE')
                  }}
                </p>
                <p class="m-0 text-xs text-n-slate-11">
                  {{
                    state.pdfFile
                      ? `${(state.pdfFile.size / 1024 / 1024).toFixed(2)} MB`
                      : t('CAPTAIN.DOCUMENTS.FORM.PDF_FILE.HELP_TEXT')
                  }}
                </p>
              </div>
            </div>

            <i class="i-lucide-upload text-n-slate-11" />
          </template>
        </Button>
      </div>
      <p v-if="formErrors.pdfFile" class="text-sm text-n-red-11">
        {{ formErrors.pdfFile }}
      </p>
    </div>

    <Input
      v-model="state.name"
      :label="t('CAPTAIN.DOCUMENTS.FORM.NAME.LABEL')"
      :placeholder="t('CAPTAIN.DOCUMENTS.FORM.NAME.PLACEHOLDER')"
    />

    <div class="flex flex-col gap-1">
      <label for="assistant" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.DOCUMENTS.FORM.ASSISTANT.LABEL') }}
      </label>
      <ComboBox
        id="assistant"
        v-model="state.assistantId"
        :options="assistantList"
        :has-error="!!formErrors.assistantId"
        :placeholder="t('CAPTAIN.DOCUMENTS.FORM.ASSISTANT.PLACEHOLDER')"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
        :message="formErrors.assistantId"
      />
    </div>

    <div class="flex gap-3 justify-between items-center w-full">
      <Button
        type="button"
        variant="faded"
        color="slate"
        :label="t('CAPTAIN.FORM.CANCEL')"
        class="w-full bg-n-alpha-2 text-n-blue-text hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        type="submit"
        :label="t('CAPTAIN.FORM.CREATE')"
        class="w-full"
        :is-loading="isLoading"
        :disabled="isLoading"
      />
    </div>
  </form>
</template>
