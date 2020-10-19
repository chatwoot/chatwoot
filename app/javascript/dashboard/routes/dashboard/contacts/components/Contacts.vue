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
      <tbody v-show="!showSearchEmptyState">
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
                  I'm the most somewhere in the middle of a c ountry.
                </p>
              </div>
            </div>
          </td>
          <td>{{ contactItem.email }}</td>
          <td></td>
          <td></td>
          <td>
            <i class="ion-more" />
          </td>
        </tr>
      </tbody>
    </table>
    <empty-state
      v-if="showSearchEmptyState"
      title="No contacts matches your search 🔍"
    />
  </section>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';

export default {
  components: {
    Thumbnail,
    EmptyState,
  },
  props: {
    contacts: {
      type: Array,
      default: () => [],
    },
    showSearchEmptyState: {
      type: Boolean,
      default: false,
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
    }
  }

  > tbody {
    > tr > td {
      padding: var(--space-small);
      padding-left: var(--space-medium);

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
    align-items: center;

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
</style>
