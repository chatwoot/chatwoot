<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDropZone } from '@vueuse/core';
import { formatBytes } from 'shared/helpers/FileHelper';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import DataImportsAPI from 'dashboard/api/dataImports';
import CsvPreview from './CsvPreview.vue';
import { IMPORT_SOURCES, importSourceConfigFor } from './importSources';
import { formatDate } from './importStatus';

const props = defineProps({
  show: { type: Boolean, default: false },
  hasActiveImport: { type: Boolean, default: false },
  integrationEnabled: { type: Boolean, default: false },
  initialSource: { type: String, default: '' },
});

const emit = defineEmits(['close', 'created']);

const { t } = useI18n();
const MAX_FILE_BYTES = 50 * 1024 * 1024;
const dialogRef = ref(null);
const sourceProvider = ref(
  props.initialSource || (props.integrationEnabled ? 'intercom' : 'csv')
);
const isFile = computed(() => sourceProvider.value === 'csv');
const file = ref(null);
const dropZoneRef = ref(null);
const fileInputRef = ref(null);
const uploadProgress = ref(0);
const sourceConfig = computed(
  () => importSourceConfigFor(sourceProvider.value) || IMPORT_SOURCES[0]
);
const importOpenedAt = ref(new Date());
const defaultImportName = computed(() => {
  const date = formatDate(importOpenedAt.value);
  if (isFile.value) return t('DATA_IMPORTS.DEFAULT_IMPORT_NAMES.CSV', { date });
  if (sourceProvider.value === 'freshdesk')
    return t('DATA_IMPORTS.DEFAULT_IMPORT_NAMES.FRESHDESK', { date });
  return t('DATA_IMPORTS.DEFAULT_IMPORT_NAMES.INTERCOM', { date });
});
const importName = ref(defaultImportName.value);
const accessToken = ref('');
const domain = ref('');
const selectedImportTypes = ref(
  isFile.value ? ['contacts'] : ['contacts', 'conversations']
);
const validationState = ref('idle');
const validationMessage = ref('');
const isCreating = ref(false);
let validationRequestId = 0;

const closeDrawer = () => emit('close');

const sourceOptions = computed(() =>
  IMPORT_SOURCES.filter(
    source => props.integrationEnabled || source.value === 'csv'
  ).map(source => ({
    ...source,
    label: source.value === 'csv' ? t('DATA_IMPORTS.CSV.SOURCE') : source.label,
  }))
);

const credentialPlaceholder = computed(() =>
  sourceProvider.value === 'freshdesk'
    ? t('DATA_IMPORTS.DRAWER.FRESHDESK_API_KEY_PLACEHOLDER')
    : t('DATA_IMPORTS.DRAWER.INTERCOM_ACCESS_KEY_PLACEHOLDER')
);
const credentialLabel = computed(() =>
  sourceProvider.value === 'freshdesk'
    ? t('DATA_IMPORTS.DRAWER.FRESHDESK_API_KEY')
    : t('DATA_IMPORTS.DRAWER.INTERCOM_ACCESS_KEY')
);

const tokenMessageType = computed(() => {
  if (validationState.value === 'valid') return 'success';
  if (validationState.value === 'invalid') return 'error';
  return 'info';
});

const canCreate = computed(
  () =>
    (isFile.value ? Boolean(file.value) : validationState.value === 'valid') &&
    selectedImportTypes.value.length > 0 &&
    !props.hasActiveImport &&
    !isCreating.value
);

const validationPayload = () => ({
  source_provider: sourceProvider.value,
  access_token: accessToken.value.trim(),
  ...(sourceConfig.value.requiresDomain ? { domain: domain.value.trim() } : {}),
  import_types: selectedImportTypes.value,
});

const hasRequiredCredentials = () =>
  accessToken.value.trim() &&
  (!sourceConfig.value.requiresDomain || domain.value.trim());

const invalidateValidation = () => {
  validationRequestId += 1;
  validationState.value = 'idle';
  validationMessage.value = '';
};

const validateSource = async () => {
  if (isFile.value) return;
  if (!hasRequiredCredentials() || !selectedImportTypes.value.length) {
    invalidateValidation();
    return;
  }

  validationRequestId += 1;
  const requestId = validationRequestId;
  validationState.value = 'validating';
  validationMessage.value = t('DATA_IMPORTS.DRAWER.VALIDATING');
  try {
    await DataImportsAPI.validateSource(validationPayload());
    if (requestId !== validationRequestId) return;

    validationState.value = 'valid';
    validationMessage.value = t('DATA_IMPORTS.DRAWER.VALID_KEY');
  } catch (error) {
    if (requestId !== validationRequestId) return;

    validationState.value = 'invalid';
    validationMessage.value =
      error?.response?.data?.message || t('DATA_IMPORTS.DRAWER.INVALID_KEY');
  }
};

const toggleImportType = type => {
  selectedImportTypes.value = selectedImportTypes.value.includes(type)
    ? selectedImportTypes.value.filter(item => item !== type)
    : [...selectedImportTypes.value, type];
};

const createImport = async () => {
  if (!canCreate.value) return;

  isCreating.value = true;
  try {
    const payload = {
      ...validationPayload(),
      name: importName.value.trim() || defaultImportName.value,
    };
    const response = isFile.value
      ? await DataImportsAPI.createFile(
          { ...payload, file: file.value },
          event => {
            uploadProgress.value = event.total
              ? Math.round((event.loaded * 100) / event.total)
              : 0;
          }
        )
      : await DataImportsAPI.create(payload);
    useAlert(t('DATA_IMPORTS.ALERTS.IMPORT_STARTED'));
    emit('created', response.data.id);
  } catch (error) {
    useAlert(
      error?.response?.data?.message || t('DATA_IMPORTS.ALERTS.IMPORT_FAILED')
    );
  } finally {
    isCreating.value = false;
  }
};

const selectFile = selected => {
  if (isCreating.value) return;
  file.value = null;
  if (!selected) return;
  if (
    !selected.name.toLowerCase().endsWith('.csv') ||
    !selected.size ||
    selected.size > MAX_FILE_BYTES
  ) {
    useAlert(t('DATA_IMPORTS.CSV.INVALID_FILE'));
    return;
  }
  file.value = selected;
};

const { isOverDropZone } = useDropZone(dropZoneRef, {
  multiple: false,
  preventDefaultForUnhandled: true,
  onDrop: files => selectFile(files?.[0]),
});

const removeFile = () => {
  file.value = null;
  fileInputRef.value.value = '';
};

watch(accessToken, invalidateValidation);
watch(domain, invalidateValidation);

watch(sourceProvider, () => {
  importName.value = defaultImportName.value;
  accessToken.value = '';
  domain.value = '';
  file.value = null;
  uploadProgress.value = 0;
  selectedImportTypes.value = isFile.value
    ? ['contacts']
    : ['contacts', 'conversations'];
  invalidateValidation();
});

watch(selectedImportTypes, () => {
  invalidateValidation();
  if (hasRequiredCredentials() && selectedImportTypes.value.length) {
    validateSource();
  }
});

watch(
  () => props.show,
  show => {
    if (show) {
      sourceProvider.value =
        props.initialSource || (props.integrationEnabled ? 'intercom' : 'csv');
      importOpenedAt.value = new Date();
      importName.value = defaultImportName.value;
      dialogRef.value?.open();
      return;
    }

    dialogRef.value?.close();
    accessToken.value = '';
    domain.value = '';
    file.value = null;
    uploadProgress.value = 0;
    validationState.value = 'idle';
    validationMessage.value = '';
  }
);
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="$t('DATA_IMPORTS.DRAWER.TITLE')"
    :confirm-button-label="$t('DATA_IMPORTS.DRAWER.IMPORT')"
    :cancel-button-label="$t('DATA_IMPORTS.DRAWER.CANCEL')"
    :disable-confirm-button="!canCreate"
    :is-loading="isCreating || validationState === 'validating'"
    width="2xl"
    overflow-y-auto
    @confirm="createImport"
    @close="closeDrawer"
  >
    <div class="flex flex-col gap-5">
      <fieldset :disabled="isCreating">
        <legend class="mb-2 text-heading-3 text-n-slate-12">
          {{ $t('DATA_IMPORTS.DRAWER.SOURCE') }}
        </legend>
        <div
          class="grid gap-2"
          :class="sourceOptions.length > 1 ? 'grid-cols-3' : 'grid-cols-1'"
        >
          <label
            v-for="source in sourceOptions"
            :key="source.value"
            class="relative cursor-pointer"
          >
            <input
              v-model="sourceProvider"
              type="radio"
              name="import-source"
              :value="source.value"
              class="peer sr-only"
            />
            <span
              class="flex h-full flex-col items-center gap-2 rounded-xl border border-n-weak bg-n-solid-1 px-2 py-3 text-body-main text-n-slate-11 transition-colors hover:bg-n-alpha-1 peer-checked:border-n-brand peer-checked:bg-n-blue-2 peer-checked:text-n-blue-11 peer-focus-visible:ring-2 peer-focus-visible:ring-n-brand peer-disabled:cursor-not-allowed"
            >
              <img
                v-if="source.icon"
                :src="source.icon"
                alt=""
                class="size-6"
              />
              <Icon v-else :icon="source.iconClass" class="size-6" />
              {{ source.label }}
            </span>
          </label>
        </div>
      </fieldset>

      <Input
        v-model="importName"
        :label="$t('DATA_IMPORTS.DRAWER.NAME')"
        :placeholder="$t('DATA_IMPORTS.DRAWER.NAME_PLACEHOLDER')"
      />

      <Input
        v-if="sourceConfig.requiresDomain"
        v-model="domain"
        autocomplete="off"
        :label="$t('DATA_IMPORTS.DRAWER.FRESHDESK_DOMAIN')"
        :placeholder="$t('DATA_IMPORTS.DRAWER.FRESHDESK_DOMAIN_PLACEHOLDER')"
        @blur="validateSource"
      />

      <Input
        v-if="!isFile"
        v-model="accessToken"
        type="password"
        autocomplete="off"
        :label="credentialLabel"
        :placeholder="credentialPlaceholder"
        :message="validationMessage"
        :message-type="tokenMessageType"
        @blur="validateSource"
      />

      <div v-if="isFile" class="flex flex-col gap-3">
        <div class="flex items-center justify-between gap-2">
          <label for="contact-csv-file" class="text-heading-3 text-n-slate-12">
            {{ $t('DATA_IMPORTS.CSV.FILE') }}
          </label>
          <a
            href="/downloads/import-contacts-sample.csv"
            download
            class="inline-flex items-center gap-1 text-label-small text-n-blue-11 hover:underline"
          >
            <Icon icon="i-lucide-download" class="size-3.5" />
            {{ $t('DATA_IMPORTS.CSV.SAMPLE') }}
          </a>
        </div>
        <div
          ref="dropZoneRef"
          class="rounded-xl border border-dashed transition-colors focus-within:ring-2 focus-within:ring-n-brand"
          :class="
            isOverDropZone
              ? 'border-n-brand bg-n-blue-2'
              : 'border-n-strong bg-n-alpha-1'
          "
        >
          <input
            id="contact-csv-file"
            ref="fileInputRef"
            type="file"
            accept=".csv,text/csv"
            :disabled="isCreating"
            class="sr-only"
            @change="selectFile($event.target.files[0])"
          />
          <div v-if="file" class="flex items-center gap-3 p-4">
            <span
              class="flex size-10 shrink-0 items-center justify-center rounded-lg border border-n-weak bg-n-solid-1"
            >
              <Icon icon="i-lucide-file-text" class="size-5 text-n-slate-11" />
            </span>
            <div class="flex min-w-0 flex-1 flex-col gap-1">
              <span class="truncate text-heading-3 text-n-slate-12">{{
                file.name
              }}</span>
              <span class="text-label-small text-n-slate-11">{{
                formatBytes(file.size)
              }}</span>
            </div>
            <Button
              type="button"
              ghost
              slate
              size="sm"
              icon="i-lucide-x"
              :aria-label="$t('DATA_IMPORTS.CSV.REMOVE_FILE')"
              :disabled="isCreating"
              @click="removeFile"
            />
          </div>
          <label
            v-else
            for="contact-csv-file"
            class="flex cursor-pointer flex-col items-center gap-2 px-4 py-6 text-center"
          >
            <Icon icon="i-lucide-upload" class="mb-1 size-6 text-n-slate-10" />
            <span class="text-body-main text-n-slate-12">{{
              $t('DATA_IMPORTS.CSV.CHOOSE_FILE')
            }}</span>
            <span class="text-label-small text-n-slate-11">{{
              $t('DATA_IMPORTS.CSV.FILE_LIMIT')
            }}</span>
          </label>
        </div>
        <CsvPreview v-if="file" :file="file" />
        <p class="text-label-small text-n-slate-11">
          {{ $t('DATA_IMPORTS.CSV.HELP') }}
        </p>
        <Banner>{{ $t('DATA_IMPORTS.CSV.SILENT_UPDATES') }}</Banner>
        <template v-if="isCreating">
          <p role="status" class="text-body-main text-n-slate-11">
            {{ $t('DATA_IMPORTS.CSV.UPLOADING', { percent: uploadProgress }) }}
          </p>
          <progress
            :value="uploadProgress"
            max="100"
            :aria-label="$t('DATA_IMPORTS.CSV.FILE')"
            class="h-1.5 w-full appearance-none overflow-hidden rounded-full border-0 bg-n-slate-3 [&::-webkit-progress-bar]:rounded-full [&::-webkit-progress-bar]:bg-n-slate-3 [&::-webkit-progress-value]:rounded-full [&::-webkit-progress-value]:bg-n-brand [&::-moz-progress-bar]:bg-n-brand"
          />
        </template>
      </div>

      <fieldset v-else class="flex flex-col gap-2.5">
        <legend class="mb-1.5 text-heading-3 text-n-slate-12">
          {{ $t('DATA_IMPORTS.DRAWER.DATA_TYPES') }}
        </legend>
        <label
          class="inline-flex cursor-pointer items-center gap-2 text-body-main text-n-slate-12"
        >
          <Checkbox
            :model-value="selectedImportTypes.includes('contacts')"
            @change="toggleImportType('contacts')"
          />
          {{ $t('DATA_IMPORTS.TYPES.CONTACTS') }}
        </label>
        <label
          class="inline-flex cursor-pointer items-center gap-2 text-body-main text-n-slate-12"
        >
          <Checkbox
            :model-value="selectedImportTypes.includes('conversations')"
            @change="toggleImportType('conversations')"
          />
          {{ $t('DATA_IMPORTS.TYPES.CONVERSATIONS') }}
        </label>
      </fieldset>

      <Banner v-if="hasActiveImport" color="amber">
        {{ $t('DATA_IMPORTS.DRAWER.ACTIVE_IMPORT') }}
      </Banner>
    </div>
  </Dialog>
</template>
