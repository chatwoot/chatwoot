<script setup>
import { ref, computed, unref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useAlert, useTrack } from 'dashboard/composables';
import { CONTACTS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';
import contactFilterItems from 'dashboard/routes/dashboard/contacts/contactFilterItems';
import { generateValuesForEditCustomViews } from 'dashboard/helper/customViewsHelper';
import countries from 'shared/constants/countries';
import {
  useCamelCase,
  useSnakeCase,
} from 'dashboard/composables/useTransformKeys';

import ContactsHeader from 'dashboard/components-next/Contacts/ContactsHeader/ContactHeader.vue';
import CreateNewContactDialog from 'dashboard/components-next/Contacts/ContactsForm/CreateNewContactDialog.vue';
import ContactExportDialog from 'dashboard/components-next/Contacts/ContactsForm/ContactExportDialog.vue';
import ContactImportDialog from 'dashboard/components-next/Contacts/ContactsForm/ContactImportDialog.vue';
import CreateSegmentDialog from 'dashboard/components-next/Contacts/ContactsForm/CreateSegmentDialog.vue';
import DeleteSegmentDialog from 'dashboard/components-next/Contacts/ContactsForm/DeleteSegmentDialog.vue';
import ContactsFilter from 'dashboard/components-next/filter/ContactsFilter.vue';

const props = defineProps({
  showSearch: {
    type: Boolean,
    default: true,
  },
  searchValue: {
    type: String,
    default: '',
  },
  activeSort: {
    type: String,
    default: 'last_activity_at',
  },
  activeOrdering: {
    type: String,
    default: '',
  },
  headerTitle: {
    type: String,
    default: '',
  },
  segmentsId: {
    type: [String, Number],
    default: 0,
  },
  activeSegment: {
    type: Object,
    default: null,
  },
  hasAppliedFilters: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'update:sort',
  'search',
  'applyFilter',
  'clearFilters',
]);

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const createNewContactDialogRef = ref(null);
const contactExportDialogRef = ref(null);
const contactImportDialogRef = ref(null);
const createSegmentDialogRef = ref(null);
const deleteSegmentDialogRef = ref(null);

const showFiltersModal = ref(false);
const appliedFilter = ref([]);
const segmentsQuery = ref({});

const appliedFilters = useMapGetter('contacts/getAppliedContactFiltersV4');
const contactAttributes = useMapGetter('attributes/getContactAttributes');
const hasActiveSegments = computed(
  () => props.activeSegment && props.segmentsId !== 0
);
const activeSegmentName = computed(() => props.activeSegment?.name);

const openCreateNewContactDialog = async () => {
  await createNewContactDialogRef.value?.contactsFormRef.resetValidation();
  createNewContactDialogRef.value?.dialogRef.open();
};
const openContactImportDialog = () =>
  contactImportDialogRef.value?.dialogRef.open();
const openContactExportDialog = () =>
  contactExportDialogRef.value?.dialogRef.open();
const openCreateSegmentDialog = () =>
  createSegmentDialogRef.value?.dialogRef.open();
const openDeleteSegmentDialog = () =>
  deleteSegmentDialogRef.value?.dialogRef.open();

const onCreate = async contact => {
  await store.dispatch('contacts/create', contact);
  createNewContactDialogRef.value?.dialogRef.close();
};

const onImport = async file => {
  try {
    await store.dispatch('contacts/import', file);
    contactImportDialogRef.value?.dialogRef.close();
    useAlert(t('IMPORT_CONTACTS.SUCCESS_MESSAGE'));
    useTrack(CONTACTS_EVENTS.IMPORT_SUCCESS);
  } catch (error) {
    useAlert(error.message ?? t('IMPORT_CONTACTS.ERROR_MESSAGE'));
    useTrack(CONTACTS_EVENTS.IMPORT_FAILURE);
  }
};

const onExport = async query => {
  try {
    await store.dispatch('contacts/export', query);
    useAlert(
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.SUCCESS_MESSAGE')
    );
  } catch (error) {
    useAlert(
      error.message ||
        t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.ERROR_MESSAGE')
    );
  }
};

const onCreateSegment = async payload => {
  try {
    const payloadData = {
      ...payload,
      query: segmentsQuery.value,
    };
    await store.dispatch('customViews/create', payloadData);
    createSegmentDialogRef.value?.dialogRef.close();
    useAlert(
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.CREATE_SEGMENT.SUCCESS_MESSAGE')
    );
  } catch {
    useAlert(
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.CREATE_SEGMENT.ERROR_MESSAGE')
    );
  }
};

const onDeleteSegment = async payload => {
  try {
    await store.dispatch('customViews/delete', {
      id: Number(props.segmentsId),
      ...payload,
    });
    router.push({
      name: 'contacts_dashboard_index',
      query: {
        page: 1,
      },
    });
    deleteSegmentDialogRef.value?.dialogRef.close();
    useAlert(
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.DELETE_SEGMENT.SUCCESS_MESSAGE')
    );
  } catch (error) {
    useAlert(
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.DELETE_SEGMENT.ERROR_MESSAGE')
    );
  }
};

const closeAdvanceFiltersModal = () => {
  showFiltersModal.value = false;
  appliedFilter.value = [];
};

const clearFilters = async () => {
  await store.dispatch('contacts/clearContactFilters');
  emit('clearFilters');
};

const onApplyFilter = async payload => {
  payload = useSnakeCase(payload);
  segmentsQuery.value = filterQueryGenerator(payload);
  emit('applyFilter', filterQueryGenerator(payload));
  showFiltersModal.value = false;
};

const onUpdateSegment = async (payload, segmentName) => {
  payload = useSnakeCase(payload);
  const payloadData = {
    ...props.activeSegment,
    name: segmentName,
    query: filterQueryGenerator(payload),
  };
  await store.dispatch('customViews/update', payloadData);
  closeAdvanceFiltersModal();
};

const setParamsForEditSegmentModal = () => {
  return {
    countries,
    filterTypes: contactFilterItems,
    allCustomAttributes: useSnakeCase(contactAttributes.value),
  };
};

const initializeSegmentToFilterModal = segment => {
  const query = unref(segment)?.query?.payload;
  if (!Array.isArray(query)) return;

  const newFilters = query.map(filter => {
    const transformed = useCamelCase(filter);
    const values = Array.isArray(transformed.values)
      ? generateValuesForEditCustomViews(
          useSnakeCase(filter),
          setParamsForEditSegmentModal()
        )
      : [];

    return {
      attributeKey: transformed.attributeKey,
      attributeModel: transformed.attributeModel,
      customAttributeType: transformed.customAttributeType,
      filterOperator: transformed.filterOperator,
      queryOperator: transformed.queryOperator ?? 'and',
      values,
    };
  });

  appliedFilter.value = [...appliedFilter.value, ...newFilters];
};

const onToggleFilters = () => {
  appliedFilter.value = [];
  if (hasActiveSegments.value) {
    initializeSegmentToFilterModal(props.activeSegment);
  } else {
    appliedFilter.value = props.hasAppliedFilters
      ? [...appliedFilters.value]
      : [
          {
            attributeKey: 'name',
            filterOperator: 'equal_to',
            values: '',
            queryOperator: 'and',
            attributeModel: 'standard',
          },
        ];
  }
  showFiltersModal.value = true;
};
</script>

<template>
  <ContactsHeader
    :show-search="showSearch"
    :search-value="searchValue"
    :active-sort="activeSort"
    :active-ordering="activeOrdering"
    :header-title="headerTitle"
    :is-segments-view="hasActiveSegments"
    :has-active-filters="hasAppliedFilters"
    :button-label="t('CONTACTS_LAYOUT.HEADER.MESSAGE_BUTTON')"
    @search="emit('search', $event)"
    @update:sort="emit('update:sort', $event)"
    @add="openCreateNewContactDialog"
    @import="openContactImportDialog"
    @export="openContactExportDialog"
    @filter="onToggleFilters"
    @create-segment="openCreateSegmentDialog"
    @delete-segment="openDeleteSegmentDialog"
  >
    <template #filter>
      <ContactsFilter
        v-if="showFiltersModal"
        v-model="appliedFilter"
        :segment-name="activeSegmentName"
        :is-segment-view="hasActiveSegments"
        class="absolute mt-1 ltr:right-0 rtl:left-0 top-full"
        @apply-filter="onApplyFilter"
        @update-segment="onUpdateSegment"
        @close="closeAdvanceFiltersModal"
        @clear-filters="clearFilters"
      />
    </template>
  </ContactsHeader>

  <CreateNewContactDialog ref="createNewContactDialogRef" @create="onCreate" />
  <ContactExportDialog ref="contactExportDialogRef" @export="onExport" />
  <ContactImportDialog ref="contactImportDialogRef" @import="onImport" />
  <CreateSegmentDialog ref="createSegmentDialogRef" @create="onCreateSegment" />
  <DeleteSegmentDialog ref="deleteSegmentDialogRef" @delete="onDeleteSegment" />
</template>
