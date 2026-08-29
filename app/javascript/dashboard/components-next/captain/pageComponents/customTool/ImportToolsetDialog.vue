<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import CustomToolsAPI from 'dashboard/api/captain/customTools';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['imported', 'close']);

const STEPS = {
  SOURCE: 'source',
  TOOLSET: 'toolset',
  CONFIGURATION: 'configuration',
};

const { t } = useI18n();
const dialogRef = ref(null);
const fileInputRef = ref(null);
const currentStep = ref(STEPS.SOURCE);
const selectedFile = ref(null);
const selectedSource = ref('');
const source = ref('');
const repositoryToolsets = ref([]);
const preview = ref(null);
const isImporting = ref(false);
const configuration = reactive({ inputs: {}, secrets: {} });
const {
  run: runPreviewRequest,
  abort: abortPreviewRequest,
  isPending: isPreviewing,
} = useAbortableRequest();

const stepTitles = computed(() => ({
  [STEPS.SOURCE]: t('CAPTAIN.CUSTOM_TOOLS.IMPORT.TITLE'),
  [STEPS.TOOLSET]: t('CAPTAIN.CUSTOM_TOOLS.IMPORT.REPOSITORY_TOOLS_LABEL'),
  [STEPS.CONFIGURATION]: preview.value?.name,
}));
const dialogTitle = computed(() => stepTitles.value[currentStep.value]);

const stepDescriptions = computed(() => ({
  [STEPS.SOURCE]: t('CAPTAIN.CUSTOM_TOOLS.IMPORT.STEPS.SOURCE'),
  [STEPS.TOOLSET]: t('CAPTAIN.CUSTOM_TOOLS.IMPORT.STEPS.TOOLSET'),
  [STEPS.CONFIGURATION]: preview.value?.description,
}));
const dialogDescription = computed(
  () => stepDescriptions.value[currentStep.value]
);

const isConfigurationComplete = computed(() =>
  (preview.value?.fields || []).every(field => {
    if (!field.required) return true;
    return configuration[field.section][field.name]?.trim();
  })
);

const resetConfiguration = () => {
  preview.value = null;
  configuration.inputs = {};
  configuration.secrets = {};
};

const reset = () => {
  abortPreviewRequest();
  currentStep.value = STEPS.SOURCE;
  selectedFile.value = null;
  selectedSource.value = '';
  source.value = '';
  repositoryToolsets.value = [];
  resetConfiguration();
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

const initializeConfiguration = data => {
  preview.value = data;
  data.fields.forEach(field => {
    configuration[field.section][field.name] = '';
  });
  currentStep.value = STEPS.CONFIGURATION;
};

const loadPreview = async ({ file, source: githubSource }) => {
  abortPreviewRequest();
  resetConfiguration();

  try {
    const response = await runPreviewRequest(signal =>
      CustomToolsAPI.previewImport({ file, source: githubSource }, { signal })
    );
    if (!response) return;

    if (response.data.toolsets) {
      repositoryToolsets.value = response.data.toolsets;
      currentStep.value = STEPS.TOOLSET;
      return;
    }

    selectedFile.value = file || null;
    selectedSource.value = githubSource || '';
    initializeConfiguration(response.data);
  } catch (error) {
    showError(error);
    if (fileInputRef.value) fileInputRef.value.value = '';
  }
};

const handleFileChange = event => {
  const [file] = event.target.files;
  if (!file) return;

  repositoryToolsets.value = [];
  loadPreview({ file });
};

const previewSource = () => {
  const githubSource = source.value.trim();
  if (!githubSource) return;

  repositoryToolsets.value = [];
  loadPreview({ source: githubSource });
};

const selectRepositoryToolset = toolset => {
  loadPreview({ source: toolset.source });
};

const goBack = () => {
  resetConfiguration();
  if (
    currentStep.value === STEPS.CONFIGURATION &&
    repositoryToolsets.value.length
  ) {
    currentStep.value = STEPS.TOOLSET;
    return;
  }

  currentStep.value = STEPS.SOURCE;
  selectedFile.value = null;
  selectedSource.value = '';
};

const handleImport = async () => {
  if (!preview.value || !isConfigurationComplete.value) return;

  isImporting.value = true;
  try {
    const { data } = await CustomToolsAPI.importToolset(
      { file: selectedFile.value, source: selectedSource.value },
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

const open = async initialSource => {
  reset();
  source.value = initialSource || '';
  dialogRef.value.open();
  if (source.value) await previewSource();
};

defineExpose({ dialogRef, open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="xl"
    :title="dialogTitle"
    :description="dialogDescription"
    :show-confirm-button="false"
    :show-cancel-button="false"
    @close="handleClose"
  >
    <div v-if="isPreviewing" class="flex flex-col items-center gap-3 py-10">
      <span class="i-lucide-loader-circle size-6 animate-spin text-n-brand" />
      <span class="text-sm text-n-slate-11">
        {{ t('CAPTAIN.CUSTOM_TOOLS.IMPORT.PREVIEWING') }}
      </span>
    </div>

    <div v-else-if="currentStep === STEPS.SOURCE" class="flex flex-col gap-5">
      <div class="flex flex-col gap-1">
        <Input
          v-model="source"
          :label="t('CAPTAIN.CUSTOM_TOOLS.IMPORT.GITHUB_LABEL')"
          :placeholder="t('CAPTAIN.CUSTOM_TOOLS.IMPORT.GITHUB_PLACEHOLDER')"
          @keyup.enter="previewSource"
        />
        <span class="text-xs text-n-slate-11">
          {{ t('CAPTAIN.CUSTOM_TOOLS.IMPORT.GITHUB_HINT') }}
        </span>
        <Button
          class="self-start mt-2"
          variant="faded"
          color="slate"
          size="sm"
          :label="t('CAPTAIN.CUSTOM_TOOLS.IMPORT.LOAD_GITHUB')"
          :disabled="!source.trim()"
          @click="previewSource"
        />
      </div>

      <div class="flex items-center gap-3 text-xs text-n-slate-10">
        <span class="h-px grow bg-n-weak" />
        {{ t('CAPTAIN.CUSTOM_TOOLS.IMPORT.OR_UPLOAD') }}
        <span class="h-px grow bg-n-weak" />
      </div>

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
    </div>

    <div v-else-if="currentStep === STEPS.TOOLSET" class="flex flex-col gap-2">
      <button
        v-for="toolset in repositoryToolsets"
        :key="toolset.source"
        type="button"
        class="flex items-center justify-between w-full gap-3 px-4 py-3 text-start rounded-lg bg-n-alpha-2 hover:bg-n-alpha-3"
        @click="selectRepositoryToolset(toolset)"
      >
        <div class="flex flex-col min-w-0 gap-1">
          <span class="text-sm font-medium text-n-slate-12">
            {{ toolset.name }}
          </span>
          <span
            v-if="toolset.description"
            class="text-xs text-n-slate-11 line-clamp-1"
          >
            {{ toolset.description }}
          </span>
          <div
            class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-n-slate-10"
          >
            <span>
              {{ toolset.tool_count }}
              {{ t('CAPTAIN.CUSTOM_TOOLS.IMPORT.TOOL_COUNT_LABEL') }}
            </span>
            <span v-if="toolset.required_configuration.length">
              {{ t('CAPTAIN.CUSTOM_TOOLS.IMPORT.REQUIRES') }}
              {{ toolset.required_configuration.join(', ') }}
            </span>
          </div>
        </div>
        <span class="i-lucide-chevron-right size-5 shrink-0 text-n-slate-10" />
      </button>
    </div>

    <div v-else-if="preview" class="flex flex-col gap-5">
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
        <ul class="flex flex-col gap-2 pe-1 overflow-y-auto list-none max-h-80">
          <li
            v-for="tool in preview.tools"
            :key="tool.title"
            class="px-3 py-2 rounded-lg bg-n-alpha-2"
          >
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
    </div>

    <template #footer>
      <div
        v-if="!isPreviewing"
        class="flex items-center justify-between w-full gap-3"
      >
        <Button
          variant="faded"
          color="slate"
          class="w-full"
          :label="
            currentStep === STEPS.SOURCE
              ? t('DIALOG.BUTTONS.CANCEL')
              : t('CAPTAIN.CUSTOM_TOOLS.IMPORT.BACK')
          "
          @click="currentStep === STEPS.SOURCE ? dialogRef.close() : goBack()"
        />
        <Button
          v-if="currentStep === STEPS.CONFIGURATION"
          class="w-full"
          :label="t('CAPTAIN.CUSTOM_TOOLS.IMPORT.CONFIRM')"
          :is-loading="isImporting"
          :disabled="!isConfigurationComplete || isImporting"
          @click="handleImport"
        />
      </div>
    </template>
  </Dialog>
</template>
