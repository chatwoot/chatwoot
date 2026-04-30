<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CONTACTS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';

import ContactsHeader from 'dashboard/components-next/Contacts/ContactsHeader/ContactHeader.vue';
import CreateNewContactDialog from 'dashboard/components-next/Contacts/ContactsForm/CreateNewContactDialog.vue';
import ContactExportDialog from 'dashboard/components-next/Contacts/ContactsForm/ContactExportDialog.vue';
import ContactImportDialog from 'dashboard/components-next/Contacts/ContactsForm/ContactImportDialog.vue';
import ContactsFilter from 'dashboard/components-next/filter/ContactsFilter.vue';

const props = defineProps({
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, default: '' },
  hasAppliedFilters: { type: Boolean, default: false },
});

const emit = defineEmits(['search', 'toggle-view', 'apply-filter', 'clear-filters']);

const { t } = useI18n();
const store = useStore();

const createNewContactDialogRef = ref(null);
const contactExportDialogRef = ref(null);
const contactImportDialogRef = ref(null);
const showFiltersModal = ref(false);
const appliedFilter = ref([]);

const appliedFilters = useMapGetter('contacts/getAppliedContactFiltersV4');

const openCreateNewContactDialog = async () => {
  await createNewContactDialogRef.value?.contactsFormRef.resetValidation();
  createNewContactDialogRef.value?.dialogRef.open();
};
const openContactImportDialog = () => contactImportDialogRef.value?.dialogRef.open();
const openContactExportDialog = () => contactExportDialogRef.value?.dialogRef.open();

const onCreate = async contact => {
  try {
    await store.dispatch('contacts/create', contact);
    createNewContactDialogRef.value?.onSuccess();
    useAlert(t('CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.SUCCESS_MESSAGE'));
  } catch (error) {
    const i18nPrefix = 'CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION';
    if (error instanceof DuplicateContactException) {
      if (error.data.includes('email')) useAlert(t(`${i18nPrefix}.EMAIL_ADDRESS_DUPLICATE`));
      else if (error.data.includes('phone_number')) useAlert(t(`${i18nPrefix}.PHONE_NUMBER_DUPLICATE`));
    } else if (error instanceof ExceptionWithMessage) {
      useAlert(error.data);
    } else {
      useAlert(t(`${i18nPrefix}.ERROR_MESSAGE`));
    }
  }
};

const onImport = async file => {
  try {
    await store.dispatch('contacts/import', file);
    contactImportDialogRef.value?.dialogRef.close();
    useAlert(t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.SUCCESS_MESSAGE'));
    useTrack(CONTACTS_EVENTS.IMPORT_SUCCESS);
  } catch (error) {
    useAlert(error.message ?? t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.ERROR_MESSAGE'));
    useTrack(CONTACTS_EVENTS.IMPORT_FAILURE);
  }
};

const onExport = async query => {
  try {
    await store.dispatch('contacts/export', query);
    useAlert(t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(error.message || t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.ERROR_MESSAGE'));
  }
};

const closeFiltersModal = () => {
  showFiltersModal.value = false;
  appliedFilter.value = [];
};

const onToggleFilters = () => {
  appliedFilter.value = props.hasAppliedFilters ? [...appliedFilters.value] : [
    { attributeKey: 'name', filterOperator: 'equal_to', values: '', queryOperator: 'and', attributeModel: 'standard' },
  ];
  showFiltersModal.value = true;
};

const onApplyFilter = payload => {
  payload = useSnakeCase(payload);
  emit('apply-filter', filterQueryGenerator(payload));
  showFiltersModal.value = false;
};

const onClearFilters = () => {
  emit('clear-filters');
};

defineExpose({ onToggleFilters });
</script>

<template>
  <ContactsHeader
    :search-value="searchValue"
    :header-title="headerTitle"
    :has-active-filters="hasAppliedFilters"
    :button-label="t('CONTACTS_LAYOUT.HEADER.MESSAGE_BUTTON')"
    view-mode="board"
    @search="emit('search', $event)"
    @toggle-view="emit('toggle-view')"
    @filter="onToggleFilters"
    @add="openCreateNewContactDialog"
    @import="openContactImportDialog"
    @export="openContactExportDialog"
  >
    <template #filter>
      <div class="absolute mt-1 ltr:-right-52 rtl:-left-52 sm:ltr:right-0 sm:rtl:left-0 top-full">
        <ContactsFilter
          v-if="showFiltersModal"
          v-model="appliedFilter"
          @apply-filter="onApplyFilter"
          @close="closeFiltersModal"
          @clear-filters="onClearFilters"
        />
      </div>
    </template>
  </ContactsHeader>

  <CreateNewContactDialog ref="createNewContactDialogRef" @create="onCreate" />
  <ContactExportDialog ref="contactExportDialogRef" @export="onExport" />
  <ContactImportDialog ref="contactImportDialogRef" @import="onImport" />
</template>
