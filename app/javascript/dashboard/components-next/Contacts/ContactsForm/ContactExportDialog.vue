<script setup>
import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';
import {
  STANDARD_CONTACT_COLUMNS,
  buildCustomColumns,
  resolveVisibleColumns,
  tableColumnsToExportKeys,
} from 'dashboard/helper/contactTableColumns';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['export']);

const { t } = useI18n();
const route = useRoute();
const { uiSettings } = useUISettings();

const dialogRef = ref(null);
const selectedFormat = ref('xlsx');
const selectedExportKeys = ref([]);

const segments = useMapGetter('customViews/getContactCustomViews');
const appliedFilters = useMapGetter('contacts/getAppliedContactFilters');
const uiFlags = useMapGetter('contacts/getUIFlags');
const getAttributesByModel = useMapGetter('attributes/getAttributesByModel');
const isExportingContact = computed(() => uiFlags.value.isExporting);

const contactAttributeDefs = computed(
  () => getAttributesByModel.value('contact_attribute') || []
);

const customColumns = computed(() =>
  buildCustomColumns(contactAttributeDefs.value)
);

const exportableOptions = computed(() => {
  const standard = STANDARD_CONTACT_COLUMNS.filter(col => col.exportKey).map(
    col => ({
      key: col.exportKey,
      label: t(`CONTACTS_LAYOUT.TABLE.COLUMNS.${col.labelKey}`),
    })
  );
  const customs = customColumns.value.map(col => ({
    key: col.exportKey,
    label: col.label,
  }));
  return [
    { key: 'id', label: t('CONTACTS_LAYOUT.TABLE.COLUMNS.ID') },
    ...standard,
    ...customs,
  ];
});

const syncSelectionFromTable = () => {
  const availableTableKeys = [
    ...STANDARD_CONTACT_COLUMNS.map(c => c.key),
    ...customColumns.value.map(c => c.key),
  ];
  const visible = resolveVisibleColumns(
    uiSettings.value?.contacts_table_columns,
    availableTableKeys,
    customColumns.value
  );
  selectedExportKeys.value = tableColumnsToExportKeys(visible, {
    includeId: true,
  });
};

const activeSegmentId = computed(() => route.params.segmentId);
const activeSegment = computed(() =>
  activeSegmentId.value
    ? segments.value.find(view => view.id === Number(activeSegmentId.value))
    : undefined
);

const formatOptions = computed(() => [
  {
    value: 'xlsx',
    label: t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.FORMAT_XLSX'),
  },
  {
    value: 'csv',
    label: t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.FORMAT_CSV'),
  },
]);

const selectedSet = computed(() => new Set(selectedExportKeys.value));

const toggleExportKey = (key, checked) => {
  const next = new Set(selectedExportKeys.value);
  if (checked) next.add(key);
  else next.delete(key);
  selectedExportKeys.value = exportableOptions.value
    .map(opt => opt.key)
    .filter(k => next.has(k));
};

const selectAllExportKeys = () => {
  selectedExportKeys.value = exportableOptions.value.map(opt => opt.key);
};

const exportContacts = async () => {
  let query = { payload: [] };

  if (activeSegmentId.value && activeSegment.value) {
    query = activeSegment.value.query;
  } else if (Object.keys(appliedFilters.value).length > 0) {
    query = filterQueryGenerator(appliedFilters.value);
  }

  const columnNames =
    selectedExportKeys.value.length > 0
      ? selectedExportKeys.value
      : tableColumnsToExportKeys(
          resolveVisibleColumns(
            null,
            STANDARD_CONTACT_COLUMNS.map(c => c.key),
            customColumns.value
          ),
          { includeId: true }
        );

  emit('export', {
    ...query,
    label: route.params.label || '',
    export_format: selectedFormat.value,
    column_names: columnNames,
  });
};

const handleDialogConfirm = async () => {
  await exportContacts();
  dialogRef.value?.close();
};

const onDialogOpen = () => {
  syncSelectionFromTable();
};

defineExpose({ dialogRef, onDialogOpen });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.TITLE')"
    :description="
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.DESCRIPTION')
    "
    :confirm-button-label="
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.CONFIRM')
    "
    :is-loading="isExportingContact"
    :disable-confirm-button="
      isExportingContact || selectedExportKeys.length === 0
    "
    @confirm="handleDialogConfirm"
  >
    <div class="flex flex-col gap-5">
      <fieldset class="flex flex-col gap-2">
        <legend class="text-sm font-medium text-n-slate-12">
          {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.FORMAT_LABEL') }}
        </legend>
        <label
          v-for="option in formatOptions"
          :key="option.value"
          class="flex items-center gap-2 text-sm text-n-slate-11 cursor-pointer"
        >
          <input
            v-model="selectedFormat"
            type="radio"
            name="contact-export-format"
            :value="option.value"
            class="accent-n-brand"
          />
          {{ option.label }}
        </label>
      </fieldset>

      <fieldset class="flex flex-col gap-2">
        <div class="flex items-center justify-between gap-2">
          <legend class="text-sm font-medium text-n-slate-12">
            {{
              t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.COLUMNS_LABEL')
            }}
          </legend>
          <div class="flex items-center gap-1">
            <Button
              size="xs"
              variant="ghost"
              color="slate"
              :label="
                t(
                  'CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.USE_TABLE_COLUMNS'
                )
              "
              @click="syncSelectionFromTable"
            />
            <Button
              size="xs"
              variant="ghost"
              color="slate"
              :label="t('CONTACTS_LAYOUT.HEADER.ACTIONS.COLUMNS.ALL')"
              @click="selectAllExportKeys"
            />
          </div>
        </div>
        <p class="text-xs text-n-slate-11">
          {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.COLUMNS_HINT') }}
        </p>
        <div
          class="flex flex-col gap-2 max-h-48 overflow-y-auto rounded-lg border border-n-weak p-3"
        >
          <label
            v-for="option in exportableOptions"
            :key="option.key"
            class="flex items-center gap-2 text-sm text-n-slate-12 cursor-pointer"
          >
            <Checkbox
              :model-value="selectedSet.has(option.key)"
              @change="
                event => toggleExportKey(option.key, event.target.checked)
              "
            />
            <span class="truncate">{{ option.label }}</span>
          </label>
        </div>
      </fieldset>
    </div>
  </Dialog>
</template>
