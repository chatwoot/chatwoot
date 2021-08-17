<template>
  <section class="contacts-table-wrap">
    <ve-table
      :fixed-header="true"
      max-height="calc(100vh - 11.4rem)"
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
    <div v-if="isLoading" class="contacts--loader">
      <spinner />
      <span>{{ $t('CONTACTS_PAGE.LIST.LOADING_MESSAGE') }}</span>
    </div>
  </section>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { VeTable } from 'vue-easytable';

import Spinner from 'shared/components/Spinner.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import timeMixin from 'dashboard/mixins/time';

export default {
  components: {
    EmptyState,
    Spinner,
    VeTable,
  },
  mixins: [clickaway, timeMixin],
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
      default: 'name',
    },
    sortOrder: {
      type: String,
      default: 'asc',
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
        return {
          ...item,
          phone_number: item.phone_number || '---',
          company: additional.company_name || '---',
          location: additional.location || '---',
          profiles: additional.social_profiles || {},
          city: additional.city || '---',
          country: additional.country || '---',
          conversationsCount: item.conversations_count || '---',
          last_activity_at: lastActivityAt
            ? this.dynamicTime(lastActivityAt)
            : '---',
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
          align: 'left',
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
                  <h6 class="sub-block-title user-name text-truncate">
                    {row.name}
                  </h6>
                  <span class="button clear small link">
                    {this.$t('CONTACTS_PAGE.LIST.VIEW_DETAILS')}
                  </span>
                </div>
              </div>
            </woot-button>
          ),
        },
        {
          field: 'email',
          key: 'email',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.EMAIL_ADDRESS'),
          align: 'left',
          sortBy: this.sortConfig.email || '',
          width: 240,
          renderBodyCell: ({ row }) => {
            if (row.email)
              return (
                <div class="text-truncate">
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
          align: 'left',
        },
        {
          field: 'company',
          key: 'company',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.COMPANY'),
          align: 'left',
        },
        {
          field: 'city',
          key: 'city',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.CITY'),
          align: 'left',
        },
        {
          field: 'country',
          key: 'country',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.COUNTRY'),
          align: 'left',
        },
        {
          field: 'profiles',
          key: 'profiles',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.SOCIAL_PROFILES'),
          align: 'left',
          renderBodyCell: ({ row }) => {
            const { profiles } = row;

            const items = Object.keys(profiles);

            if (!items.length) return '---';

            return (
              <div class="cell--social-profiles">
                {items.map(
                  profile =>
                    profiles[profile] && (
                      <a
                        target="_blank"
                        rel="noopener noreferrer nofollow"
                        href={`https://${profile}.com/${profiles[profile]}`}
                      >
                        <i class={`ion-social-${profile}`} />
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
          align: 'left',
        },
        {
          field: 'conversationsCount',
          key: 'conversationsCount',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.CONVERSATIONS'),
          width: 150,
          align: 'left',
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
@import '~dashboard/assets/scss/mixins';

.contacts-table-wrap {
  flex: 1 1;
  height: 100%;
  overflow: hidden;
}

.contacts-table-wrap::v-deep {
  .ve-table {
    padding-bottom: var(--space-large);
  }
  .row--user-block {
    align-items: center;
    display: flex;
    text-align: left;

    .user-block {
      min-width: 0;
    }

    .user-thumbnail-box {
      margin-right: var(--space-small);
    }

    .user-name {
      font-size: var(--font-size-small);
      margin: 0;
      text-transform: capitalize;
    }

    .user-email {
      margin: 0;
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
    top: -4px;
  }
}

.contacts--loader {
  align-items: center;
  display: flex;
  font-size: var(--font-size-default);
  justify-content: center;
  padding: var(--space-big);
}

.cell--social-profiles {
  a {
    color: var(--s-300);
    display: inline-block;
    font-size: var(--font-size-medium);
    min-width: var(--space-large);
    text-align: center;
  }
}
</style>
