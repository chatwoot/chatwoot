<script setup>
import { computed, h } from 'vue';
// import { ref, computed, defineEmits } from 'vue';
// import { useMapGetter } from 'dashboard/composables/store';
// import { mapGetters } from 'vuex';
// import { VeTable } from 'vue-easytable';

import Table from 'dashboard/components/table/Table.vue';

import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
  getSortedRowModel,
} from '@tanstack/vue-table';

import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useI18n } from 'vue-i18n';

// Cell components
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
  // sortParam: {
  //   type: String,
  //   default: 'last_activity_at',
  // },
  // sortOrder: {
  //   type: String,
  //   default: 'desc',
  // },
});

// const emit = defineEmits(['onSortChange']);

const { t } = useI18n();

// const sortConfig = computed(() => {
//   return { [props.sortParam]: props.sortOrder };
// });

// const sortOption = ref({
//   sortAlways: true,
//   sortChange: params => emit('onSortChange', params),
// });

// const isRTL = useMapGetter('accounts/isRTL');

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
    cell: cellProps => h(TelCell, { phoneNumber: cellProps.getValue() }),
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

const table = useVueTable({
  get data() {
    return tableData.value;
  },
  columns,
  columnResizeMode: 'onChange',
  getCoreRowModel: getCoreRowModel(),
  getSortedRowModel: getSortedRowModel(),
});
</script>

<template>
  <section
    class="flex-1 h-full -mt-1 overflow-hidden bg-white contacts-table-wrap dark:bg-slate-900"
  >
    <section class="overflow-x-auto">
      <Table fixed :table="table" />
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
