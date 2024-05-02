<template>
  <section
    class="contacts-table-wrap bg-white dark:bg-slate-900 flex-1 h-full overflow-hidden -mt-1"
  >
    <ve-table
      :fixed-header="true"
      max-height="calc(100vh - 7.125rem)"
      scroll-width="187rem"
      :columns="columns"
      :table-data="tableData"
      :border-around="false"
      :sort-option="sortOption"
    />

    <empty-state
      v-if="showSearchEmptyState"
      :title="$t('CONTACTS_PAGE.LIST.404')"
    />
    <empty-state
      v-else-if="!isLoading && !contacts.length"
      :title="$t('CONTACTS_PAGE.LIST.NO_CONTACTS')"
    />
    <div v-if="isLoading" class="items-center flex text-base justify-center">
      <spinner />
      <span>{{ $t('CONTACTS_PAGE.LIST.LOADING_MESSAGE') }}</span>
    </div>
  </section>
</template>

<script>
import { VeTable } from 'vue-easytable';
import { getCountryFlag } from 'dashboard/helper/flag';

import Spinner from 'shared/components/Spinner.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import timeMixin from 'dashboard/mixins/time';
import rtlMixin from 'shared/mixins/rtlMixin';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

export default {
  components: {
    EmptyState,
    Spinner,
    VeTable,
  },
  mixins: [timeMixin, rtlMixin],
  props: {
    contacts: {
      type: Array,
      default: () => [],
    },
    showSearchEmptyState: {
      type: Boolean,
      default: false,
    },
    onClickContact: {
      type: Function,
      default: () => {},
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    activeContactId: {
      type: [String, Number],
      default: '',
    },
    sortParam: {
      type: String,
      default: 'last_activity_at',
    },
    sortOrder: {
      type: String,
      default: 'desc',
    },
  },
  data() {
    return {
      sortConfig: {},
      sortOption: {
        sortAlways: true,
        sortChange: params => this.$emit('on-sort-change', params),
      },
    };
  },
  computed: {
    tableData() {
      if (this.isLoading) {
        return [];
      }
      return this.contacts.map(item => {
        // Note: The attributes used here is in snake case
        // as it simplier the sort attribute calculation
        const additional = item.additional_attributes || {};
        const { last_activity_at: lastActivityAt } = item;
        const { created_at: createdAt } = item;
        return {
          ...item,
          phone_number: item.phone_number || '---',
          company: additional.company_name || '---',
          profiles: additional.social_profiles || {},
          city: additional.city || '---',
          country: additional.country,
          countryCode: additional.country_code,
          conversationsCount: item.conversations_count || '---',
          last_activity_at: lastActivityAt
            ? this.dynamicTime(lastActivityAt)
            : '---',
          created_at: createdAt ? this.dynamicTime(createdAt) : '---',
        };
      });
    },
    columns() {
      return [
        {
          field: 'name',
          key: 'name',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.NAME'),
          fixed: 'left',
          align: this.isRTLView ? 'right' : 'left',
          sortBy: this.sortConfig.name || '',
          width: 300,
          renderBodyCell: ({ row }) => (
            <woot-button
              variant="clear"
              onClick={() => this.onClickContact(row.id)}
            >
              <div class="row--user-block">
                <Thumbnail
                  src={row.thumbnail}
                  size="32px"
                  username={row.name}
                  status={row.availability_status}
                />
                <div class="user-block">
                  <h6 class="text-base overflow-hidden whitespace-nowrap text-ellipsis">
                    <router-link
                      to={`/app/accounts/${this.$route.params.accountId}/contacts/${row.id}`}
                      class="user-name"
                    >
                      {row.name}
                    </router-link>
                  </h6>
                  <button class="button clear small link view-details--button">
                    {this.$t('CONTACTS_PAGE.LIST.VIEW_DETAILS')}
                  </button>
                </div>
              </div>
            </woot-button>
          ),
        },
        {
          field: 'email',
          key: 'email',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.EMAIL_ADDRESS'),
          align: this.isRTLView ? 'right' : 'left',
          sortBy: this.sortConfig.email || '',
          width: 240,
          renderBodyCell: ({ row }) => {
            if (row.email)
              return (
                <div class="overflow-hidden whitespace-nowrap text-ellipsis text-woot-500 dark:text-woot-500">
                  <a
                    target="_blank"
                    rel="noopener noreferrer nofollow"
                    href={`mailto:${row.email}`}
                  >
                    {row.email}
                  </a>
                </div>
              );
            return '---';
          },
        },
        {
          field: 'phone_number',
          key: 'phone_number',
          sortBy: this.sortConfig.phone_number || '',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.PHONE_NUMBER'),
          align: this.isRTLView ? 'right' : 'left',
        },
        {
          field: 'company',
          key: 'company',
          sortBy: this.sortConfig.company_name || '',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.COMPANY'),
          align: this.isRTLView ? 'right' : 'left',
        },
        {
          field: 'city',
          key: 'city',
          sortBy: this.sortConfig.city || '',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.CITY'),
          align: this.isRTLView ? 'right' : 'left',
        },
        {
          field: 'country',
          key: 'country',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.COUNTRY'),
          align: this.isRTLView ? 'right' : 'left',
          sortBy: this.sortConfig.country || '',
          renderBodyCell: ({ row }) => {
            if (row.country) {
              return (
                <div class="overflow-hidden whitespace-nowrap text-ellipsis">
                  {`${getCountryFlag(row.countryCode)} ${row.country}`}
                </div>
              );
            }
            return '---';
          },
        },
        {
          field: 'profiles',
          key: 'profiles',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.SOCIAL_PROFILES'),
          align: this.isRTLView ? 'right' : 'left',
          renderBodyCell: ({ row }) => {
            const { profiles } = row;

            const items = Object.keys(profiles);

            if (!items.length) return '---';

            return (
              <div class="cell--social-profiles flex gap-0.5 items-center">
                {items.map(
                  profile =>
                    profiles[profile] && (
                      <a
                        target="_blank"
                        rel="noopener noreferrer nofollow"
                        href={`https://${profile}.com/${profiles[profile]}`}
                      >
                        <FluentIcon icon={`brand-${profile}`} />
                      </a>
                    )
                )}
              </div>
            );
          },
        },
        {
          field: 'last_activity_at',
          key: 'last_activity_at',
          sortBy: this.sortConfig.last_activity_at || '',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.LAST_ACTIVITY'),
          align: this.isRTLView ? 'right' : 'left',
        },
        {
          field: 'created_at',
          key: 'created_at',
          sortBy: this.sortConfig.created_at || '',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.CREATED_AT'),
          align: this.isRTLView ? 'right' : 'left',
        },
      ];
    },
  },
  watch: {
    sortOrder() {
      this.setSortConfig();
    },
    sortParam() {
      this.setSortConfig();
    },
  },
  mounted() {
    this.setSortConfig();
  },
  methods: {
    setSortConfig() {
      this.sortConfig = { [this.sortParam]: this.sortOrder };
    },
  },
};
</script>

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
