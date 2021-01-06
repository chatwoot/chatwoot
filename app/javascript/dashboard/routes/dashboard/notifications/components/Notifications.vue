<template>
  <section>
    <table class="woot-table contacts-table">
      <button class="button nice icon success button--fixed-right-top">
        <i class="icon ion-android-download"></i>
        Mark All Done
      </button>
      <tbody>
        <tr
          v-for="notificationItem in notifications"
          :key="notificationItem.id"
        >
          <td>
            <div class="row-main-info">
              <thumbnail
                :src="notificationItem.primary_actor.meta.sender.thumbnail"
                size="40px"
                :username="notificationItem.primary_actor.meta.sender.name"
                :status="
                  notificationItem.primary_actor.meta.sender.availability_status
                "
              />
              <div>
                <h4 class="sub-block-title user-name">
                  {{ `#${notificationItem.id}` }}
                </h4>
                <p class="user-about">
                  {{ notificationItem.push_message_title }}
                </p>
              </div>
            </div>
          </td>
          <td>{{ notificationItem.notification_type }}</td>
          <td>
            {{ dynamicTime(notificationItem.created_at) }}
          </td>
          <td></td>
          <td></td>
          <td>
            <div v-if="!notificationItem.read_at" class="read--view--bubble" />
          </td>
        </tr>
      </tbody>
    </table>
  </section>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import timeMixin from '../../../../mixins/time';

export default {
  components: {
    Thumbnail,
  },
  mixins: [timeMixin],
  props: {
    notifications: {
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
  .read--view--bubble {
    width: var(--space-one);
    height: var(--space-one);
    border-radius: 50%;
    background: var(--color-woot);
  }
}
</style>
