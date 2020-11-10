<template>
  <section class="contacts-table-wrap">
    <table class="woot-table contacts-table">
      <thead>
        <th
          v-for="thHeader in $t('CONTACTS_PAGE.LIST.TABLE_HEADER')"
          :key="thHeader"
        >
          {{ thHeader }}
        </th>
      </thead>
      <tbody v-show="showTableData">
        <tr
          v-for="contactItem in contacts"
          :key="contactItem.id"
          :class="{ 'is-active': contactItem.id === activeContactId }"
          @click="() => onClickContact(contactItem.id)"
        >
          <td>
            <div class="row-main-info">
              <thumbnail
                :src="contactItem.thumbnail"
                size="36px"
                :username="contactItem.name"
                :status="contactItem.availability_status"
              />
              <div>
                <h4 class="sub-block-title user-name">
                  {{ contactItem.name }}
                </h4>
                <p class="user-email">
                  {{ contactItem.email || '--' }}
                </p>
              </div>
            </div>
          </td>
          <td>{{ contactItem.phone_number || '--' }}</td>
          <td class="conversation-count-item">
            {{ contactItem.conversations_count }}
          </td>
          <td>
            {{ contactItem.last_contacted_at || '--' }}
          </td>
        </tr>
      </tbody>
    </table>
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
import Spinner from 'shared/components/Spinner.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';

export default {
  components: {
    Thumbnail,
    EmptyState,
    Spinner,
  },
  mixins: [clickaway],
  props: {
    contacts: {
      type: Array,
      default: () => [],
    },
    showSearchEmptyState: {
      type: Boolean,
      default: false,
    },
    openEditModal: {
      type: Function,
      default: () => {},
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
      type: String,
      default: '',
    },
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
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/mixins';

.contacts-table-wrap {
  @include scroll-on-hover;
  background: var(--color-background-light);
  flex: 1 1;
  height: 100%;
}

.contacts-table {
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
      text-transform: capitalize;
      margin: 0;
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
