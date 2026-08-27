<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import CustomToolsAPI from 'dashboard/api/captain/customTools';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const emit = defineEmits(['imported', 'close']);

const { t } = useI18n();
const dialogRef = ref(null);
const fileInputRef = ref(null);
const selectedFile = ref(null);
const preview = ref(null);
const isImporting = ref(false);
const configuration = reactive({ inputs: {}, secrets: {} });
const {
  run: runPreviewRequest,
  abort: abortPreviewRequest,
  isPending: isPreviewing,
} = useAbortableRequest();

const isConfigurationComplete = computed(() =>
  (preview.value?.fields || []).every(field => {
    if (!field.required) return true;
    return configuration[field.section][field.name]?.trim();
  })
);

const reset = () => {
  abortPreviewRequest();
  selectedFile.value = null;
  preview.value = null;
  configuration.inputs = {};
  configuration.secrets = {};
  if (fileInputRef.value) fileInputRef.value.value = '';
};

const showError = error => {
  const parsedError = parseAPIErrorResponse(error);
  const message =
    typeof parsedError === 'string'
      ? parsedError
      : t('CAPTAIN.CUSTOM_TOOLS.IMPORT.ERROR_MESSAGE');
  useAlert(message);
};

const handleFileChange = async event => {
  const [file] = event.target.files;
  abortPreviewRequest();
  selectedFile.value = null;
  preview.value = null;
  configuration.inputs = {};
  configuration.secrets = {};
  if (!file) return;

  selectedFile.value = file;
  try {
    const response = await runPreviewRequest(signal =>
      CustomToolsAPI.previewImport(file, { signal })
    );
    if (!response) return;

    const { data } = response;
    preview.value = data;
    data.fields.forEach(field => {
      configuration[field.section][field.name] = '';
    });
  } catch (error) {
    showError(error);
    reset();
  }
};

const handleImport = async () => {
  if (!selectedFile.value || !isConfigurationComplete.value) return;

  isImporting.value = true;
  try {
    const { data } = await CustomToolsAPI.importToolset(
      selectedFile.value,
      configuration
    );
    useAlert(
      t('CAPTAIN.CUSTOM_TOOLS.IMPORT.SUCCESS_MESSAGE', {
        count: data.imported_count,
      })
    );
    emit('imported');
    dialogRef.value.close();
  } catch (error) {
    showError(error);
  } finally {
    isImporting.value = false;
  }
};

const handleClose = () => {
  reset();
  emit('close');
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="xl"
    :title="t('CAPTAIN.CUSTOM_TOOLS.IMPORT.TITLE')"
    :description="t('CAPTAIN.CUSTOM_TOOLS.IMPORT.DESCRIPTION')"
    :confirm-button-label="t('CAPTAIN.CUSTOM_TOOLS.IMPORT.CONFIRM')"
    :disable-confirm-button="
      !preview || !isConfigurationComplete || isPreviewing
    "
    :is-loading="isImporting"
    @confirm="handleImport"
    @close="handleClose"
  >
    <div class="flex flex-col gap-5">
      <div class="flex flex-col gap-1">
        <label
          for="captain-toolset-file"
          class="text-heading-3 text-n-slate-12"
        >
          {{ t('CAPTAIN.CUSTOM_TOOLS.IMPORT.FILE_LABEL') }}
        </label>
        <input
          id="captain-toolset-file"
          ref="fileInputRef"
          type="file"
          accept=".yml,.yaml,application/yaml,text/yaml"
          class="block w-full h-10 px-3 py-2 text-sm rounded-lg outline outline-1 outline-offset-[-1px] outline-n-weak bg-n-alpha-black2 text-n-slate-12 file:me-3 file:border-0 file:bg-transparent file:text-sm file:font-medium"
          @change="handleFileChange"
        />
        <span class="text-xs text-n-slate-11">
          {{ t('CAPTAIN.CUSTOM_TOOLS.IMPORT.FILE_HINT') }}
        </span>
      </div>

      <div
        v-if="isPreviewing"
        class="flex items-center gap-2 text-sm text-n-slate-11"
      >
        <span class="i-lucide-loader-circle size-4 animate-spin" />
        {{ t('CAPTAIN.CUSTOM_TOOLS.IMPORT.PREVIEWING') }}
      </div>

      <template v-if="preview">
        <div class="flex flex-col gap-1">
          <span class="text-base font-medium text-n-slate-12">
            {{ preview.name }}
          </span>
          <span v-if="preview.description" class="text-sm text-n-slate-11">
            {{ preview.description }}
          </span>
        </div>

        <div v-if="preview.fields.length" class="flex flex-col gap-3">
          <Input
            v-for="field in preview.fields"
            :key="`${field.section}-${field.name}`"
            v-model="configuration[field.section][field.name]"
            :type="field.secret ? 'password' : 'text'"
            :label="field.label"
            :placeholder="field.placeholder || ''"
            :required="field.required"
          />
        </div>

        <div class="flex flex-col gap-2">
          <span class="text-heading-3 text-n-slate-12">
            {{ t('CAPTAIN.CUSTOM_TOOLS.IMPORT.TOOLS_LABEL') }}
          </span>
          <ul class="flex flex-col gap-2 list-none">
            <li
              v-for="tool in preview.tools"
              :key="tool.title"
              class="flex items-start gap-2 px-3 py-2 rounded-lg bg-n-alpha-2"
            >
              <span class="i-lucide-wrench size-4 mt-0.5 text-n-slate-10" />
              <div class="flex flex-col min-w-0">
                <span class="text-sm font-medium text-n-slate-12">
                  {{ tool.title }}
                </span>
                <span v-if="tool.description" class="text-xs text-n-slate-11">
                  {{ tool.description }}
                </span>
              </div>
            </li>
          </ul>
        </div>
      </template>
    </div>
  </Dialog>
</template>
