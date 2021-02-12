<template>
  <section class="contacts-table-wrap">
    <ve-table
      :fixed-header="true"
      max-height="90vh"
      scroll-width="130vw"
      style="width: 100%"
      :columns="columns"
      :table-data="tableData"
      :sort-option="sortOption"
    />

    <empty-state
      v-if="showSearchEmptyState"
      :title="$t('CONTACTS_PAGE.LIST.404')"
    />
    <div v-if="isLoading" class="contacts--loader">
      <spinner />
      <span>{{ $t('CONTACTS_PAGE.LIST.LOADING_MESSAGE') }}</span>
    </div>
  </section>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { VeTable } from 'vue-easytable'; // import library

import Spinner from 'shared/components/Spinner.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import timeMixin from 'dashboard/mixins/time';

export default {
  components: {
    // eslint-disable-next-line vue/no-unused-components
    Thumbnail,
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
  },
  data() {
    return {
      sortOption: {
        sortChange: params => {
          console.log('sortChange::', params);
          // this.sortChange(params);
        },
      },
      columns: [
        {
          field: 'name',
          sortBy: 'asc',
          key: 'a',
          title: 'Name',
          fixed: 'left',
          align: 'left',
          // eslint-disable-next-line no-unused-vars
          renderBodyCell: ({ row }, h) => {
            return (
              <div
                class="row-main-info"
                onClick={() => this.onClickContact(row.id)}
              >
                <Thumbnail
                  src={row.thumbnail}
                  size="36px"
                  username={row.name}
                  status={row.availability_status}
                />
                <div>
                  <h4 class="sub-block-title user-name">{row.name}</h4>
                  <button class="button clear small">view details</button>
                </div>
              </div>
            );
          },
        },
        {
          field: 'email',
          sortBy: 'asc',
          key: 'b',
          title: 'Email',
          align: 'left',
          // eslint-disable-next-line no-unused-vars
          renderBodyCell: ({ row }, h) => {
            if (row.email)
              return (
                <div>
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
          field: 'phone',
          sortBy: 'asc',
          key: 'c',
          title: 'Phone',
          align: 'left',
        },
        {
          field: 'company',
          sortBy: 'asc',
          key: 'd',
          title: 'Company',
          align: 'left',
        },
        {
          field: 'city',
          sortBy: 'asc',
          key: 'e',
          title: 'city',
          align: 'left',
        },
        {
          field: 'country',
          sortBy: 'asc',
          key: 'f',
          title: 'Country',
          align: 'left',
        },
        {
          field: 'profiles',
          key: 'g',
          title: 'Social Profiles',
          align: 'left',
          // eslint-disable-next-line no-unused-vars
          renderBodyCell: ({ row }, h) => {
            const { profiles } = row;

            const items = Object.keys(profiles);

            if (!items.length) return '---';

            return (
              <div class="cell-social-profiles">
                {items.map(
                  profile =>
                    profiles[profile] && (
                      <div>
                        <a
                          target="_blank"
                          rel="noopener noreferrer nofollow"
                          href={`https://${profile}.com/${profiles[profile]}`}
                        >{`${profile}.com/${profiles[profile]}`}</a>
                      </div>
                    )
                )}
              </div>
            );
          },
        },
        {
          field: 'lastSeen',
          sortBy: 'asc',
          key: 'h',
          title: 'Last seen',
          align: 'left',
        },
        {
          field: 'conversations_count',
          sortBy: 'asc',
          key: 'i',
          title: 'Conversations',
          width: 200,
          align: 'left',
        },
      ],
    };
  },
  computed: {
    currentRoute() {
      return ' ';
    },
    showTableData() {
      return !this.showSearchEmptyState && !this.isLoading;
    },
    tableData() {
      return this.contacts.map(item => {
        const additional = item.additional_attributes || {};
        const { last_seen_at: lastSeenAt } = item;
        return {
          ...item,
          phone: item.phone_number || '---',
          company: additional.company_name || '---',
          location: additional.location || '---',
          profiles: additional.social_profiles || {},
          city: additional.city || '---',
          country: additional.country || '---',
          conversations_count: item.conversations_count || '---',
          lastSeen: lastSeenAt ? this.dynamicTime(lastSeenAt) : '---',
        };
      });
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/mixins';

.contacts-table-wrap {
  /* @include scroll-on-hover; */
  flex: 1 1;
  height: 100%;
  overflow: hidden;
}

.contacts-table-wrap::v-deep {
  .ve-table {
    padding-bottom: var(--space-large);
  }
  .row-main-info {
    display: flex;
    align-items: center;

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

  .ve-table-header-th,
  .ve-table-body-td {
    padding-left: var(--space-medium) !important;
  }
}
</style>
