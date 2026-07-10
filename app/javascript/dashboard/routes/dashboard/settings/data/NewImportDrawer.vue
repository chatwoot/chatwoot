<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Modal from 'dashboard/components/Modal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import DataImportsAPI from 'dashboard/api/dataImports';
import { IMPORT_SOURCES } from './importSources';

const props = defineProps({
  show: { type: Boolean, default: false },
  hasActiveImport: { type: Boolean, default: false },
});

const emit = defineEmits(['close', 'created']);

const { t } = useI18n();
const sourceProvider = ref('intercom');
const importName = ref(t('DATA_IMPORTS.DEFAULT_IMPORT_NAME'));
const accessToken = ref('');
const selectedImportTypes = ref(['contacts', 'conversations']);
const validationState = ref('idle');
const validationMessage = ref('');
const isCreating = ref(false);
let validationRequestId = 0;

const modalVisible = computed({
  get: () => props.show,
  set: () => undefined,
});

const closeDrawer = () => emit('close');

const sourceOptions = computed(() =>
  IMPORT_SOURCES.map(({ value, label }) => ({ value, label }))
);

const tokenMessageType = computed(() => {
  if (validationState.value === 'valid') return 'success';
  if (validationState.value === 'invalid') return 'error';
  return 'info';
});

const canCreate = computed(
  () =>
    validationState.value === 'valid' &&
    selectedImportTypes.value.length > 0 &&
    !props.hasActiveImport &&
    !isCreating.value
);

const validationPayload = () => ({
  source_provider: sourceProvider.value,
  access_token: accessToken.value.trim(),
  import_types: selectedImportTypes.value,
});

const invalidateValidation = () => {
  validationRequestId += 1;
  validationState.value = 'idle';
  validationMessage.value = '';
};

const validateSource = async () => {
  if (!accessToken.value.trim() || !selectedImportTypes.value.length) {
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
    const response = await DataImportsAPI.create({
      ...validationPayload(),
      name: importName.value.trim() || t('DATA_IMPORTS.DEFAULT_IMPORT_NAME'),
    });
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

watch(accessToken, invalidateValidation);

watch(selectedImportTypes, () => {
  invalidateValidation();
  if (accessToken.value.trim() && selectedImportTypes.value.length) {
    validateSource();
  }
});

watch(
  () => props.show,
  show => {
    if (show) return;

    accessToken.value = '';
    validationState.value = 'idle';
    validationMessage.value = '';
  }
);
</script>

<template>
  <Modal
    v-model:show="modalVisible"
    modal-type="right-aligned"
    @close="closeDrawer"
  >
    <form class="flex h-full flex-col" @submit.prevent="createImport">
      <div class="border-b border-n-weak px-6 py-5">
        <h2 class="text-heading-2 text-n-slate-12">
          {{ $t('DATA_IMPORTS.DRAWER.TITLE') }}
        </h2>
      </div>

      <div class="flex flex-1 flex-col gap-5 overflow-y-auto px-6 py-5">
        <label class="flex flex-col gap-2 text-heading-3 text-n-slate-12">
          {{ $t('DATA_IMPORTS.DRAWER.SOURCE') }}
          <Select
            v-model="sourceProvider"
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
          v-model="accessToken"
          type="password"
          autocomplete="off"
          :label="$t('DATA_IMPORTS.DRAWER.ACCESS_KEY')"
          :placeholder="$t('DATA_IMPORTS.DRAWER.ACCESS_KEY_PLACEHOLDER')"
          :message="validationMessage"
          :message-type="tokenMessageType"
          @blur="validateSource"
        />

        <fieldset class="flex flex-col gap-3">
          <legend class="text-heading-3 text-n-slate-12">
            {{ $t('DATA_IMPORTS.DRAWER.DATA_TYPES') }}
          </legend>
          <label class="inline-flex items-center gap-2 text-sm text-n-slate-12">
            <input
              type="checkbox"
              class="rounded border-n-strong"
              :checked="selectedImportTypes.includes('contacts')"
              @change="toggleImportType('contacts')"
            />
            {{ $t('DATA_IMPORTS.TYPES.CONTACTS') }}
          </label>
          <label class="inline-flex items-center gap-2 text-sm text-n-slate-12">
            <input
              type="checkbox"
              class="rounded border-n-strong"
              :checked="selectedImportTypes.includes('conversations')"
              @change="toggleImportType('conversations')"
            />
            {{ $t('DATA_IMPORTS.TYPES.CONVERSATIONS') }}
          </label>
        </fieldset>

        <p v-if="hasActiveImport" class="text-sm text-n-amber-11">
          {{ $t('DATA_IMPORTS.DRAWER.ACTIVE_IMPORT') }}
        </p>
      </div>

      <div class="flex justify-end gap-3 border-t border-n-weak px-6 py-4">
        <Button
          type="button"
          ghost
          slate
          :label="$t('DATA_IMPORTS.DRAWER.CANCEL')"
          @click="closeDrawer"
        />
        <Button
          type="submit"
          icon="i-lucide-download"
          :label="$t('DATA_IMPORTS.DRAWER.IMPORT')"
          :disabled="!canCreate"
          :is-loading="isCreating || validationState === 'validating'"
        />
      </div>
    </form>
  </Modal>
</template>
