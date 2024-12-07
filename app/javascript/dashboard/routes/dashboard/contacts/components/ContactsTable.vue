<script setup>
import { h, ref, computed, defineEmits } from 'vue';
import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
} from '@tanstack/vue-table';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useI18n } from 'vue-i18n';

import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';

// Table components
import Table from 'dashboard/components/table/Table.vue';
import NameCell from './ContactsTable/NameCell.vue';
import EmailCell from './ContactsTable/EmailCell.vue';
import TelCell from './ContactsTable/TelCell.vue';
import CountryCell from './ContactsTable/CountryCell.vue';
import ProfilesCell from './ContactsTable/ProfilesCell.vue';

const props = defineProps({
  contacts: {
    type: Array,
    default: () => [],
  },
  showSearchEmptyState: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['onSortChange']);
const { t } = useI18n();

const tableData = computed(() => {
  if (props.isLoading) {
    return [];
  }

  return props.contacts.map(item => {
    // Note: The attributes used here is in snake case
    // as it simplier the sort attribute calculation
    const additional = item.additional_attributes || {};
    const { last_activity_at: lastActivityAt } = item;
    const { created_at: createdAt } = item;
    return {
      ...item,
      profiles: additional.social_profiles || {},
      last_activity_at: lastActivityAt ? dynamicTime(lastActivityAt) : null,
      created_at: createdAt ? dynamicTime(createdAt) : null,
    };
  });
});

const defaulSpanRender = cellProps =>
  h(
    'span',
    {
      class: cellProps.getValue() ? '' : 'text-slate-300 dark:text-slate-700',
    },
    cellProps.getValue() ? cellProps.getValue() : '---'
  );

const columnHelper = createColumnHelper();
const columns = [
  columnHelper.accessor('name', {
    header: t('CONTACTS_PAGE.LIST.TABLE_HEADER.NAME'),
    cell: cellProps => h(NameCell, cellProps),
    size: 250,
  }),
  columnHelper.accessor('email', {
    header: t('CONTACTS_PAGE.LIST.TABLE_HEADER.EMAIL_ADDRESS'),
    cell: cellProps => h(EmailCell, { email: cellProps.getValue() }),
    size: 250,
  }),
  columnHelper.accessor('phone_number', {
    header: t('CONTACTS_PAGE.LIST.TABLE_HEADER.PHONE_NUMBER'),
    size: 200,
    cell: cellProps =>
      h(TelCell, {
        phoneNumber: cellProps.getValue(),
        defaultCountry: cellProps.row.original.country_code,
      }),
  }),
  columnHelper.accessor('company_name', {
    header: t('CONTACTS_PAGE.LIST.TABLE_HEADER.COMPANY'),
    size: 200,
    cell: defaulSpanRender,
  }),
  columnHelper.accessor('city', {
    header: t('CONTACTS_PAGE.LIST.TABLE_HEADER.CITY'),
    cell: defaulSpanRender,
    size: 200,
  }),
  columnHelper.accessor('country', {
    header: t('CONTACTS_PAGE.LIST.TABLE_HEADER.COUNTRY'),
    size: 200,
    cell: cellProps =>
      h(CountryCell, {
        countryCode: cellProps.row.original.country_code,
        country: cellProps.getValue(),
      }),
  }),
  columnHelper.accessor('profiles', {
    header: t('CONTACTS_PAGE.LIST.TABLE_HEADER.SOCIAL_PROFILES'),
    size: 200,
    enableSorting: false,
    cell: cellProps =>
      h(ProfilesCell, {
        profiles: cellProps.getValue(),
      }),
  }),
  columnHelper.accessor('last_activity_at', {
    header: t('CONTACTS_PAGE.LIST.TABLE_HEADER.LAST_ACTIVITY'),
    size: 200,
    cell: defaulSpanRender,
  }),
  columnHelper.accessor('created_at', {
    header: t('CONTACTS_PAGE.LIST.TABLE_HEADER.CREATED_AT'),
    size: 200,
    cell: defaulSpanRender,
  }),
];

// type ColumnSort = {
//   id: string
//   desc: boolean
// }
// type SortingState = ColumnSort[]
const sortingState = ref([{ last_activity_at: 'desc' }]);

const table = useVueTable({
  get data() {
    return tableData.value;
  },
  columns,
  enableMultiSort: false,
  getCoreRowModel: getCoreRowModel(),
  state: {
    get sorting() {
      return sortingState.value;
    },
  },
  onSortingChange: updater => {
    // onSortingChange returns a callback that allows us to trigger the sort when we need
    // See more docs here: https://tanstack.com/table/latest/docs/api/features/sorting#onsortingchange
    // IMO, I don't like this API, but it's what we have for now. Would be great if we could just listen the the changes
    // to the sorting state and emit the event when it changes
    // But we can easily wrap this later as a separate composable
    const updatedSortState = updater(sortingState.value);
    // we pick the first item from the array, as we are not using multi-sorting
    const [sort] = updatedSortState;

    if (sort) {
      sortingState.value = updatedSortState;
      emit('onSortChange', { [sort.id]: sort.desc ? 'desc' : 'asc' });
    } else {
      // If the sorting is empty, we reset to the default sorting
      sortingState.value = [{ last_activity_at: 'desc' }];
      emit('onSortChange', {});
    }
  },
});
</script>

<template>
  <section class="flex-1 h-full overflow-auto bg-white dark:bg-slate-900">
    <section class="overflow-x-auto">
      <Table fixed :table="table" type="compact" />
    </section>

    <EmptyState
      v-if="showSearchEmptyState"
      :title="$t('CONTACTS_PAGE.LIST.404')"
    />
    <EmptyState
      v-else-if="!isLoading && !contacts.length"
      :title="$t('CONTACTS_PAGE.LIST.NO_CONTACTS')"
    />
    <div v-if="isLoading" class="flex items-center justify-center text-base">
      <Spinner />
      <span>{{ $t('CONTACTS_PAGE.LIST.LOADING_MESSAGE') }}</span>
    </div>
  </section>
</template>
