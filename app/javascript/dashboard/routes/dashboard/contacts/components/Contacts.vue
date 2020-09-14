<template>
  <section>
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
      <tbody>
        <tr v-for="contactItem in contacts" :key="contactItem.id">
          <td>
            <div class="item-selector-wrap">
              <input type="checkbox" />
            </div>
          </td>
          <td>
            <div class="row-main-info">
              <thumbnail
                :src="contactItem.thumbnail"
                size="40px"
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
  </section>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  components: {
    Thumbnail,
  },
  props: {
    contacts: {
      type: Array,
      default: () => [],
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
.contacts-table {
  > thead {
    border-bottom: 1px solid var(--color-border);

    > th:first-child {
      width: var(--space-large);
    }
  }

  > tbody {
    > tr > td {
      padding: var(--space-slab) var(--space-small);
      &:first-child .item-selector-wrap {
        width: var(--space-large);
        display: flex;
        justify-content: center;
        align-items: center;
        box-sizing: border-box;
        > input {
          margin: 0;
        }
      }
    }
  }
  .row-main-info {
    display: flex;

    .user-thumbnail-box {
      margin-right: var(--space-small);
    }

    .user-name {
      text-transform: capitalize;
    }

    .user-about {
      margin: 0;
    }
  }
}
</style>
