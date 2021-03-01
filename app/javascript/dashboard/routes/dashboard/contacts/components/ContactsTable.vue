<template>
  <section class="contacts-table-wrap">
    <ve-table
      :fixed-header="true"
      max-height="calc(100vh - 11.4rem)"
      scroll-width="187rem"
      :columns="columns"
      :table-data="tableData"
      :border-around="false"
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
  },
  data() {
    return {
      columns: [
        {
          field: 'name',
          key: 'name',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.NAME'),
          fixed: 'left',
          align: 'left',
          width: 300,
          renderBodyCell: ({ row }) => (
            <button
              class="row--user-block cursor-pointer"
              onClick={() => this.onClickContact(row.id)}
            >
              <Thumbnail
                src={row.thumbnail}
                size="36px"
                username={row.name}
                status={row.availability_status}
              />
              <div>
                <h6 class="sub-block-title user-name text-truncate">
                  {row.name}
                </h6>
                <button class="button clear small">
                  {this.$t('CONTACTS_PAGE.LIST.VIEW_DETAILS')}
                </button>
              </div>
            </button>
          ),
        },
        {
          field: 'email',
          key: 'email',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.EMAIL_ADDRESS'),
          align: 'left',
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
          field: 'phone',
          key: 'phone',
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
          field: 'lastSeen',
          key: 'lastSeen',
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
      ],
    };
  },
  computed: {
    tableData() {
      if (this.isLoading) {
        return [];
      }
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
          conversationsCount: item.conversations_count || '---',
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
    padding: var(--space-slab) var(--space-two) !important;
  }

  .ve-table-header-th {
    font-size: var(--font-size-mini) !important;
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
