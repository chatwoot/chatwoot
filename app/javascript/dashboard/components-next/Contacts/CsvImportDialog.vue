<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import CsvImportAPI from 'dashboard/api/csvImport';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const emit = defineEmits(['close', 'imported']);

const { t } = useI18n();

const dialogRef = ref(null);
const fileInputRef = ref(null);
const selectedFile = ref(null);
const isImporting = ref(false);
const result = ref(null);

const open = () => dialogRef.value?.open();
const close = () => dialogRef.value?.close();

defineExpose({ open, close });

const onFileChange = event => {
  const [file] = event.target.files || [];
  selectedFile.value = file || null;
  result.value = null;
};

const triggerFileInput = () => fileInputRef.value?.click();

const handleImport = async () => {
  if (!selectedFile.value) return;
  isImporting.value = true;
  result.value = null;
  try {
    const { data } = await CsvImportAPI.import(selectedFile.value);
    result.value = data;
    useAlert(
      t('CONTACTS_LAYOUT.CSV_IMPORT.SUCCESS', {
        created: data.imported,
        updated: data.updated,
        companies: data.companies_created + data.companies_updated,
      })
    );
    emit('imported', data);
    selectedFile.value = null;
  } catch (error) {
    useAlert(
      error?.response?.data?.error || t('CONTACTS_LAYOUT.CSV_IMPORT.ERROR')
    );
  } finally {
    isImporting.value = false;
  }
};
</script>

<template>
  <Dialog ref="dialogRef" @close="emit('close')">
    <template #header>
      <h3 class="text-lg font-medium text-n-slate-12">
        {{ t('CONTACTS_LAYOUT.CSV_IMPORT.TITLE') }}
      </h3>
    </template>
    <div class="flex flex-col gap-4 p-1">
      <p class="text-sm text-n-slate-11">
        {{ t('CONTACTS_LAYOUT.CSV_IMPORT.INFO') }}
      </p>

      <input
        ref="fileInputRef"
        type="file"
        accept=".csv"
        class="hidden"
        @change="onFileChange"
      />

      <Button
        variant="faded"
        color="slate"
        :label="t('CONTACTS_LAYOUT.CSV_IMPORT.CHOOSE_FILE')"
        @click="triggerFileInput"
      />

      <p v-if="selectedFile" class="text-sm text-n-slate-12">
        {{ selectedFile.name }}
      </p>

      <div
        v-if="result"
        class="text-sm text-n-slate-12 rounded-lg bg-n-alpha-2 p-3"
      >
        <div>
          {{ t('CONTACTS_LAYOUT.CSV_IMPORT.RESULT.CREATED') }}:
          {{ result.imported }}
        </div>
        <div>
          {{ t('CONTACTS_LAYOUT.CSV_IMPORT.RESULT.UPDATED') }}:
          {{ result.updated }}
        </div>
        <div>
          {{ t('CONTACTS_LAYOUT.CSV_IMPORT.RESULT.SKIPPED') }}:
          {{ result.skipped }}
        </div>
        <div>
          {{ t('CONTACTS_LAYOUT.CSV_IMPORT.RESULT.COMPANIES') }}:
          {{ result.companies_created + result.companies_updated }}
        </div>
      </div>

      <div class="flex gap-3 justify-end">
        <Button
          variant="faded"
          color="slate"
          :label="t('CONTACTS_LAYOUT.CSV_IMPORT.CANCEL')"
          @click="close"
        />
        <Button
          :label="t('CONTACTS_LAYOUT.CSV_IMPORT.IMPORT')"
          :disabled="!selectedFile || isImporting"
          :is-loading="isImporting"
          @click="handleImport"
        />
      </div>
    </div>
  </Dialog>
</template>
