<script setup>
import { reactive, computed, ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { minLength, requiredIf, url } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainDocuments/getUIFlags'),
};

const initialState = {
  name: '',
  url: '',
  documentType: 'url',
  pdfFile: null,
};

const state = reactive({ ...initialState });
const fileInputRef = ref(null);

const validationRules = {
  url: {
    required: requiredIf(() => state.documentType === 'url'),
    url: requiredIf(() => state.documentType === 'url' && url),
    minLength: requiredIf(() => state.documentType === 'url' && minLength(1)),
  },
  pdfFile: {
    required: requiredIf(() => state.documentType === 'pdf'),
  },
};

const documentTypeOptions = [
  { value: 'url', label: t('CAPTAIN.DOCUMENTS.FORM.TYPE.URL') },
  { value: 'pdf', label: t('CAPTAIN.DOCUMENTS.FORM.TYPE.PDF') },
];

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const hasPdfFileError = computed(() => v$.value.pdfFile.$error);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`CAPTAIN.DOCUMENTS.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  url: getErrorMessage('url', 'URL'),
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
    if (file.size > MAX_FILE_SIZE) {
      // 10MB
      useAlert(t('CAPTAIN.DOCUMENTS.FORM.PDF_FILE.TOO_LARGE'));
      event.target.value = '';
      return;
    }
    state.pdfFile = file;
    state.name = file.name.replace(/\.pdf$/i, '');
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
  formData.append('document[assistant_id]', props.assistantId);

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
    <div class="flex flex-col gap-1">
      <label
        for="documentType"
        class="mb-0.5 text-sm font-medium text-on-surface"
      >
        {{ t('CAPTAIN.DOCUMENTS.FORM.TYPE.LABEL') }}
      </label>
      <ComboBox
        id="documentType"
        v-model="state.documentType"
        :options="documentTypeOptions"
      />
    </div>

    <Input
      v-if="state.documentType === 'url'"
      v-model="state.url"
      :label="t('CAPTAIN.DOCUMENTS.FORM.URL.LABEL')"
      :placeholder="t('CAPTAIN.DOCUMENTS.FORM.URL.PLACEHOLDER')"
      :message="formErrors.url"
      :message-type="formErrors.url ? 'error' : 'info'"
    />

    <div v-if="state.documentType === 'pdf'" class="flex flex-col gap-2">
      <label class="text-sm font-medium text-on-surface">
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
        <button
          type="button"
          class="flex w-full items-center justify-between gap-3 rounded-lg border border-solid bg-surface-container-lowest px-3 py-3 text-left outline-none transition-all duration-200 focus-visible:ring-2 focus-visible:ring-secondary/25 focus-visible:ring-offset-0"
          :class="
            hasPdfFileError
              ? 'border-error hover:border-error'
              : state.pdfFile
                ? 'border-secondary/40 hover:border-secondary/60'
                : 'border-outline-variant/30 hover:border-outline-variant/50'
          "
          @click="openFileDialog"
        >
          <div class="flex min-w-0 flex-1 items-center gap-3">
            <div
              class="flex size-10 shrink-0 items-center justify-center rounded-lg border border-outline-variant/10 bg-surface-container-high"
            >
              <Icon icon="i-ph-file-pdf" class="size-5 text-secondary" />
            </div>
            <div class="flex min-w-0 flex-1 flex-col gap-0.5">
              <p class="m-0 truncate text-sm font-medium text-on-surface">
                {{
                  state.pdfFile
                    ? state.pdfFile.name
                    : t('CAPTAIN.DOCUMENTS.FORM.PDF_FILE.CHOOSE_FILE')
                }}
              </p>
              <p class="m-0 text-xs text-on-surface-variant">
                {{
                  state.pdfFile
                    ? `${(state.pdfFile.size / 1024 / 1024).toFixed(2)} MB`
                    : t('CAPTAIN.DOCUMENTS.FORM.PDF_FILE.HELP_TEXT')
                }}
              </p>
            </div>
          </div>
          <Icon
            icon="i-lucide-upload"
            class="size-5 shrink-0 text-on-surface-variant"
          />
        </button>
      </div>
      <p v-if="formErrors.pdfFile" class="text-xs text-error">
        {{ formErrors.pdfFile }}
      </p>
    </div>

    <Input
      v-model="state.name"
      :label="t('CAPTAIN.DOCUMENTS.FORM.NAME.LABEL')"
      :placeholder="t('CAPTAIN.DOCUMENTS.FORM.NAME.PLACEHOLDER')"
    />

    <div class="flex w-full items-center justify-between gap-3">
      <Button
        type="button"
        faded
        slate
        class="w-full"
        :label="t('CAPTAIN.FORM.CANCEL')"
        @click="handleCancel"
      />
      <Button
        type="submit"
        teal
        class="w-full"
        :label="t('CAPTAIN.FORM.CREATE')"
        :is-loading="isLoading"
        :disabled="isLoading"
      />
    </div>
  </form>
</template>
