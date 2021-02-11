<template>
  <section class="contacts-table-wrap">
    <ve-table
      :fixed-header="true"
      max-height="900px"
      :scroll-width="2000"
      style="width: 100%"
      :columns="columns"
      :table-data="tableData"
    ></ve-table>

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
      columns: [
        {
          field: 'name',
          key: 'a',
          title: 'Name',
          fixed: 'left',
          align: 'left',
        },
        {
          field: 'email',
          key: 'b',
          title: 'Email',
          align: 'left',
        },
        {
          field: 'phone_number',
          key: 'c',
          title: 'Phone',
          align: 'left',
        },
        {
          field: 'company_name',
          key: 'd',
          title: 'Company',
          align: 'left',
        },
        {
          field: 'location',
          key: 'e',
          title: 'Location',
          align: 'left',
        },
        {
          field: 'social_profiles',
          key: 'f',
          title: 'Social Profiles',
          align: 'left',
        },
        {
          field: 'conversations_count',
          key: 'g',
          title: 'Conversations',
        },
      ],
    };
  },
  computed: {
    currentRoute() {
      return ' ';
    },
    sidebarClassName() {
      if (this.isOnDesktop) {
        return '';
      }
      if (this.isSidebarOpen) {
        return 'off-canvas is-open ';
      }
      return 'off-canvas position-left is-transition-push is-closed';
    },
    contentClassName() {
      if (this.isOnDesktop) {
        return '';
      }
      if (this.isSidebarOpen) {
        return 'off-canvas-content is-open-left has-transition-push has-position-left';
      }
      return 'off-canvas-content';
    },
    showTableData() {
      return !this.showSearchEmptyState && !this.isLoading;
    },
    tableData() {
      return this.contacts.map(item => {
        const additional = item.additional_attributes || {};
        return {
          name: item.name,
          email: item.email || '---',
          phone: item.phone || '---',
          company_name: additional.company_name || '---',
          location: additional.location || '---',
          social_profiles: additional.social_profiles || '---',
          conversations_count: item.conversations_count || '---',
        };
      });
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/mixins';

.contacts-table-wrap {
  @include scroll-on-hover;
  flex: 1 1;
  height: 100%;
}

.contacts-table {
  margin-top: -1px;

  > thead {
    border-bottom: 1px solid var(--color-border);
    background: white;

    > th:first-child {
      padding-left: var(--space-medium);
      width: 30%;
    }
  }

  > tbody {
    > tr {
      cursor: pointer;

      &:hover {
        background: var(--b-50);
      }

      &.is-active {
        background: var(--b-100);
      }

      > td {
        padding: var(--space-slab);

        &:first-child {
          padding-left: var(--space-medium);
        }

        &.conversation-count-item {
          padding-left: var(--space-medium);
        }
      }
    }
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
}

.contacts--loader {
  font-size: var(--font-size-default);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-big);
}
</style>
