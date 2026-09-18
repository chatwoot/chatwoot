<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import DataImportsAPI from 'dashboard/api/dataImports';
import { IMPORT_SOURCES, importSourceConfigFor } from './importSources';

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
const uploadProgress = ref(0);
const sourceConfig = computed(
  () => importSourceConfigFor(sourceProvider.value) || IMPORT_SOURCES[0]
);
const defaultImportName = computed(() => {
  if (isFile.value) return t('DATA_IMPORTS.DEFAULT_IMPORT_NAMES.CSV');
  if (sourceProvider.value === 'freshdesk')
    return t('DATA_IMPORTS.DEFAULT_IMPORT_NAMES.FRESHDESK');
  return t('DATA_IMPORTS.DEFAULT_IMPORT_NAMES.INTERCOM');
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
  ).map(({ value, label }) => ({
    value,
    label: value === 'csv' ? t('DATA_IMPORTS.CSV.SOURCE') : label,
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

const selectFile = event => {
  const selected = event.target.files[0];
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
    width="md"
    @confirm="createImport"
    @close="closeDrawer"
  >
    <div class="flex flex-col gap-4">
      <label class="flex flex-col gap-1.5 text-heading-3 text-n-slate-12">
        {{ $t('DATA_IMPORTS.DRAWER.SOURCE') }}
        <Select
          v-model="sourceProvider"
          :disabled="isCreating"
          class="!w-full [&>select]:w-full"
          :options="sourceOptions"
        />
      </label>

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
        <label class="text-heading-3 text-n-slate-12">
          {{ $t('DATA_IMPORTS.CSV.FILE') }}
          <input
            type="file"
            accept=".csv,text/csv"
            :disabled="isCreating"
            class="mt-2 block w-full text-body-main"
            @change="selectFile"
          />
        </label>
        <p class="text-body-main text-n-slate-11">
          {{ $t('DATA_IMPORTS.CSV.HELP') }}
        </p>
        <p class="text-body-main text-n-slate-11">
          {{ $t('DATA_IMPORTS.CSV.SILENT_UPDATES') }}
        </p>
        <a
          href="/downloads/import-contacts-sample.csv"
          download
          class="text-n-blue-11"
        >
          <span>{{ $t('DATA_IMPORTS.CSV.SAMPLE') }}</span>
        </a>
        <p
          v-if="isCreating"
          role="status"
          class="text-body-main text-n-slate-11"
        >
          {{ $t('DATA_IMPORTS.CSV.UPLOADING', { percent: uploadProgress }) }}
        </p>
        <progress
          v-if="isCreating"
          :value="uploadProgress"
          max="100"
          :aria-label="$t('DATA_IMPORTS.CSV.FILE')"
          class="h-2 w-full accent-n-brand"
        />
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

      <p
        v-if="hasActiveImport"
        class="rounded-lg bg-n-amber-2 px-3 py-2 text-body-main text-n-amber-11"
      >
        {{ $t('DATA_IMPORTS.DRAWER.ACTIVE_IMPORT') }}
      </p>
    </div>
  </Dialog>
</template>
