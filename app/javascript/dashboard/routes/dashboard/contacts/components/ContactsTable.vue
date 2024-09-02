<script setup>
import { computed, h } from 'vue';
// import { ref, computed, defineEmits } from 'vue';
// import { useMapGetter } from 'dashboard/composables/store';
// import { mapGetters } from 'vuex';
// import { VeTable } from 'vue-easytable';

import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
  getSortedRowModel,
  FlexRender,
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
      company: additional.company_name || '---',
      profiles: additional.social_profiles || {},
      city: additional.city || '---',
      country: additional.country,
      countryCode: additional.country_code,
      conversationsCount: item.conversations_count || '---',
      last_activity_at: lastActivityAt ? dynamicTime(lastActivityAt) : '---',
      created_at: createdAt ? dynamicTime(createdAt) : '---',
    };
  });
});

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
  columnHelper.accessor('company', {
    header: t('CONTACTS_PAGE.LIST.TABLE_HEADER.COMPANY'),
    size: 200,
  }),
  columnHelper.accessor('city', {
    header: t('CONTACTS_PAGE.LIST.TABLE_HEADER.CITY'),
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
    cell: cellProps =>
      h(ProfilesCell, {
        profiles: cellProps.getValue(),
      }),
  }),
  columnHelper.accessor('last_activity_at', {
    header: t('CONTACTS_PAGE.LIST.TABLE_HEADER.LAST_ACTIVITY'),
    size: 200,
  }),
  columnHelper.accessor('created_at', {
    header: t('CONTACTS_PAGE.LIST.TABLE_HEADER.CREATED_AT'),
    size: 200,
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
      <table class="table-fixed">
        <thead>
          <tr
            v-for="headerGroup in table.getHeaderGroups()"
            :key="headerGroup.id"
          >
            <th
              v-for="header in headerGroup.headers"
              :key="header.id"
              :style="{
                width: `${header.getSize()}px`,
              }"
              @click="header.column.getToggleSortingHandler()?.($event)"
            >
              <template v-if="!header.isPlaceholder">
                <FlexRender
                  :render="header.column.columnDef.header"
                  :props="header.getContext()"
                />
                <!-- <SortButton v-if="header.column.getCanSort()" :header="header" />
              <ResizeHandle
                v-if="header.column.getCanResize()"
                :header="header"
              /> -->
              </template>
            </th>
          </tr>
        </thead>

        <tbody>
          <tr v-for="row in table.getRowModel().rows" :key="row.id">
            <td v-for="cell in row.getVisibleCells()" :key="cell.id">
              <FlexRender
                :render="cell.column.columnDef.cell"
                :props="cell.getContext()"
              />
            </td>
          </tr>
        </tbody>
      </table>
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

<style lang="scss" scoped>
.contacts-table-wrap::v-deep {
  .ve-table {
    @apply pb-8;
  }

  .row--user-block {
    @apply items-center flex text-left;

    .user-block {
      @apply items-start flex flex-col my-0 mx-2;
    }

    .user-name {
      @apply text-sm font-medium m-0 capitalize;
    }

    .view-details--button {
      @apply text-slate-600 dark:text-slate-200;
    }

    .user-email {
      @apply m-0;
    }
  }

  .ve-table-header-th {
    padding: var(--space-small) var(--space-two) !important;
  }

  .ve-table-body-td {
    padding: var(--space-small) var(--space-two) !important;
  }

  .ve-table-header-th {
    font-size: var(--font-size-mini) !important;
  }

  .ve-table-sort {
    @apply -top-1;
  }
}

.cell--social-profiles {
  a {
    @apply text-slate-300 dark:text-slate-400 text-lg min-w-[2rem] text-center;
  }
}
</style>
