<template>
  <section class="contacts-table-wrap">
    <table class="woot-table contacts-table">
      <thead>
        <!-- Header -->
        <th
          v-for="thHeader in $t('CONTACTS_PAGE.LIST.TABLE_HEADER')"
          :key="thHeader"
        >
          {{ thHeader }}
        </th>
        <th><i class="ion-chevron-down" /></th>
      </thead>
      <tbody v-show="showTableData">
        <tr v-for="contactItem in contacts" :key="contactItem.id">
          <!-- <td>
            <div class="item-selector-wrap">
              <input type="checkbox" />
            </div>
          </td> -->
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
                <p class="user-about">
                  {{
                    contactItem.additional_attributes
                      ? contactItem.additional_attributes.description
                      : ''
                  }}
                </p>
              </div>
            </div>
          </td>
          <td>{{ contactItem.email }}</td>
          <td></td>
          <td></td>
          <td>
            <div
              class="context-menu-wrap"
              @click="() => onContextMenuClick(contactItem.id)"
            >
              <i class="ion-more context-menu-icon" />
              <div
                v-if="activeContextMenuId === contactItem.id"
                v-on-clickaway="closeStatusMenu"
                class="dropdown-pane sleek bottom open"
              >
                <ul class="vertical dropdown menu">
                  <li>
                    <a href="#" @click="() => openEditModal(contactItem.id)">
                      {{ $t('CONTACTS_PAGE.LIST.EDIT_BUTTON') }}
                    </a>
                  </li>
                </ul>
              </div>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    <empty-state
      v-if="showSearchEmptyState"
      title="No contacts matches your search 🔍"
    />
    <div v-if="isLoading" class="contacts--loader">
      <spinner></spinner> Loading...
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
    isLoading: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      activeContextMenuId: '',
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
  },
  methods: {
    onContextMenuClick(id) {
      this.activeContextMenuId = id;
    },
    closeStatusMenu() {
      this.activeContextMenuId = '';
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/mixins';

.contacts-table-wrap {
  @include scroll-on-hover;
  flex: 1 1;
  background: var(--color-background-light);
}

.contacts-table {
  > thead {
    border-bottom: 1px solid var(--color-border);
    background: white;

    > th:first-child {
      /* width: var(--space-large); */
      padding-left: var(--space-medium);
      width: 40%;
    }
  }

  > tbody {
    > tr > td {
      padding: var(--space-small);
      padding-left: var(--space-medium);

      &:last-child {
        padding-left: var(--space-one);
      }
      /* &:first-child .item-selector-wrap {
        width: var(--space-large);
        display: flex;
        justify-content: center;
        align-items: center;
        box-sizing: border-box;
        > input {
          margin: 0;
        }
      } */
    }
  }
  .row-main-info {
    display: flex;
    align-items: flex-start;

    .user-thumbnail-box {
      margin-right: var(--space-small);
    }

    .user-name {
      text-transform: capitalize;
      margin: 0;
    }

    .user-about {
      margin: 0;
    }
  }
}

.context-menu-wrap {
  position: relative;
  .dropdown-pane.open {
    width: 120px;
    display: block;
    visibility: visible;
    top: 24px;
    position: absolute;
    left: -94px;
    right: unset;
  }

  .context-menu-icon {
    cursor: pointer;
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
