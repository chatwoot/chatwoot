<template>
  <section
    class="contacts-table-wrap bg-white dark:bg-slate-900 flex-1 h-full overflow-hidden -mt-1"
  >
    <ve-table
      style="width: 100%"
      :fixed-header="true"
      max-height="calc(100vh - 7.125rem)"
      scroll-width="300rem"
      :columns="columns"
      :table-data="tableData"
      :border-around="false"
      :border-x="true"
      :border-y="true"
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
import { mixin as clickaway } from 'vue-clickaway';
import { VeTable } from 'vue-easytable';

import Spinner from 'shared/components/Spinner.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import timeMixin from 'dashboard/mixins/time';
import contactMixin from 'dashboard/mixins/contactMixin';
import rtlMixin from 'shared/mixins/rtlMixin';
import { format } from 'date-fns';

export default {
  components: {
    EmptyState,
    Spinner,
    VeTable,
  },
  mixins: [clickaway, timeMixin, rtlMixin, contactMixin],
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
        return {
          ...item,
          ...item.custom_attributes,
          stage_name: item.stage ? item.stage.name : null,
          action_description: item.conversation_plans?.length
            ? this.currentConversationPlanText(item.conversation_plans)
            : null,
          assignee_name: item.assignee ? item.assignee.name : null,
          team_name: item.team ? item.team.name : null,
          product_name: item.product
            ? `${item.product.short_name} - ${item.product.name}`
            : null,
        };
      });
    },
    columns() {
      const nameColumn = {
        field: 'name',
        key: 'name',
        width: 300,
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.NAME'),
        fixed: 'left',
        align: this.isRTLView ? 'right' : 'left',
        sortBy: this.sortConfig.name || '',
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
      };

      const basicColumn = {
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.GROUP_BASIC'),
        children: [
          {
            field: 'email',
            key: 'email',
            title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.EMAIL_ADDRESS'),
            align: this.isRTLView ? 'right' : 'left',
            sortBy: this.sortConfig.email || '',
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
        ],
      };

      const customColumn = {
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.GROUP_CUSTOM'),
        children: [],
      };
      const custom_attribute_definitions =
        this.$store.getters['attributes/getAttributesByModel'](
          'contact_attribute'
        );
      custom_attribute_definitions.forEach(item => {
        const column = {
          field: item.attribute_key,
          key: item.attribute_key,
          title: item.attribute_display_name,
          align: this.isRTLView ? 'right' : 'left',
        };
        if (item.attribute_display_type === 'date') {
          column.renderBodyCell = ({ row }) => {
            if (row[item.attribute_key]) {
              return format(new Date(row[item.attribute_key]), 'dd/MM/yyyy');
            }
            return null;
          };
        }
        customColumn.children.push(column);
      });

      const salesColumn = {
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.GROUP_SALES'),
        children: [],
      };
      salesColumn.children.push({
        field: 'initial_channel_type',
        key: 'initial_channel_type',
        sortBy: this.sortConfig.initial_channel_type || '',
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.INITIAL_CHANNEL'),
        align: this.isRTLView ? 'right' : 'left',
      });
      salesColumn.children.push({
        field: 'stage_name',
        key: 'stage_name',
        sortBy: this.sortConfig.stage_id || '',
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.STAGE_NAME'),
        align: this.isRTLView ? 'right' : 'left',
      });
      salesColumn.children.push({
        field: 'last_note',
        key: 'last_note',
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.LAST_NOTE'),
        align: this.isRTLView ? 'right' : 'left',
      });
      salesColumn.children.push({
        field: 'action_description',
        key: 'action_description',
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.ACTION_DESCRIPTION'),
        align: this.isRTLView ? 'right' : 'left',
      });
      salesColumn.children.push({
        field: 'assignee_name',
        key: 'assignee_name',
        sortBy: this.sortConfig.assignee_id || '',
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.ASSIGNEE'),
        align: this.isRTLView ? 'right' : 'left',
      });
      salesColumn.children.push({
        field: 'team_name',
        key: 'team_name',
        sortBy: this.sortConfig.team_id || '',
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.TEAM_NAME'),
        align: this.isRTLView ? 'right' : 'left',
      });
      salesColumn.children.push({
        field: 'product_name',
        key: 'product_name',
        sortBy: this.sortConfig.product_id || '',
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.PRODUCT_NAME'),
        align: this.isRTLView ? 'right' : 'left',
      });
      salesColumn.children.push({
        field: 'po_value',
        key: 'po_value',
        sortBy: this.sortConfig.po_value || '',
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.PO_VALUE'),
        align: this.isRTLView ? 'right' : 'left',
      });
      salesColumn.children.push({
        field: 'po_date',
        key: 'po_date',
        sortBy: this.sortConfig.po_date || '',
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.PO_DATE'),
        align: this.isRTLView ? 'right' : 'left',
        renderBodyCell: ({ row }) => {
          if (row.po_date) return format(new Date(row.po_date), 'dd/MM/yy');
          return '';
        },
      });
      salesColumn.children.push({
        field: 'po_note',
        key: 'po_note',
        sortBy: this.sortConfig.po_note || '',
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.PO_NOTE'),
        align: this.isRTLView ? 'right' : 'left',
      });

      const trackingColumn = {
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.GROUP_TRACKING'),
        children: [],
      };
      trackingColumn.children.push({
        field: 'last_stage_changed_at',
        key: 'last_stage_changed_at',
        sortBy: this.sortConfig.last_stage_changed_at || '',
        renderBodyCell: ({ row }) => {
          if (row.last_stage_changed_at)
            return this.dynamicTime(row.last_stage_changed_at);
          return '-';
        },
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.LAST_STAGE_CHANGED'),
        align: this.isRTLView ? 'right' : 'left',
      });
      trackingColumn.children.push({
        field: 'last_activity_at',
        key: 'last_activity_at',
        sortBy: this.sortConfig.last_activity_at || '',
        renderBodyCell: ({ row }) => {
          if (row.last_activity_at)
            return this.dynamicTime(row.last_activity_at);
          return '-';
        },
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.LAST_ACTIVITY'),
        align: this.isRTLView ? 'right' : 'left',
      });
      trackingColumn.children.push({
        field: 'updated_at',
        key: 'updated_at',
        sortBy: this.sortConfig.updated_at || '',
        renderBodyCell: ({ row }) => {
          if (row.updated_at) return this.dynamicTime(row.updated_at);
          return '-';
        },
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.UPDATED_AT'),
        align: this.isRTLView ? 'right' : 'left',
      });
      trackingColumn.children.push({
        field: 'created_at',
        key: 'created_at',
        sortBy: this.sortConfig.created_at || '',
        renderBodyCell: ({ row }) => {
          if (row.created_at) return this.dynamicTime(row.created_at);
          return '-';
        },
        title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.CREATED_AT'),
        align: this.isRTLView ? 'right' : 'left',
      });

      return [
        nameColumn,
        basicColumn,
        salesColumn,
        customColumn,
        trackingColumn,
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
