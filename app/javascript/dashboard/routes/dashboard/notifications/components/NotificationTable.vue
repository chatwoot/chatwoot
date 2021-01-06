<template>
  <section class="notifications-table-wrap">
    <table class="woot-table notifications-table">
      <button class="button nice icon success button--fixed-right-top">
        <i class="icon ion-android-download"></i>
        Mark All Done
      </button>
      <tbody v-show="showTableData">
        <tr
          v-for="notificationItem in notifications"
          :key="notificationItem.id"
          @click="() => onClickNotification(notificationItem)"
        >
          <td>
            <div class="row-main-info">
              <thumbnail
                :src="notificationItem.primary_actor.meta.sender.thumbnail"
                size="36px"
                :username="notificationItem.primary_actor.meta.sender.name"
                :status="
                  notificationItem.primary_actor.meta.sender.availability_status
                "
              />
              <div>
                <h4 class="sub-block-title notification-name">
                  {{ `#${notificationItem.id}` }}
                </h4>
                <p class="notification-title">
                  {{ notificationItem.push_message_title }}
                </p>
              </div>
            </div>
          </td>
          <td>{{ notificationItem.notification_type }}</td>
          <td>
            {{ dynamicTime(notificationItem.created_at) }}
          </td>
          <td>
            <div v-if="!notificationItem.read_at" class="read--view--bubble" />
          </td>
        </tr>
      </tbody>
    </table>
    <empty-state
      v-if="showEmptyResult"
      :title="$t('NOTIFICATIONS_PAGE.LIST.404')"
    />
    <div v-if="isLoading" class="notifications--loader">
      <spinner />
      <span>{{ $t('NOTIFICATIONS_PAGE.LIST.LOADING_MESSAGE') }}</span>
    </div>
  </section>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import timeMixin from '../../../../mixins/time';

export default {
  components: {
    Thumbnail,
    Spinner,
    EmptyState,
  },
  mixins: [timeMixin],
  props: {
    notifications: {
      type: Array,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    onClickNotification: {
      type: Function,
      default: () => {},
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
      return !this.isLoading;
    },
    showEmptyResult() {
      return !this.isLoading && this.notifications.length === 0;
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/mixins';

.notifications-table-wrap {
  @include scroll-on-hover;
  flex: 1 1;
  height: 100%;
}

.notifications-table {
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

    .notification-id {
      font-size: var(--font-size-small);
      margin: 0;
      text-transform: capitalize;
    }

    .notification-title {
      margin: 0;
    }
  }
}

.notifications--loader {
  font-size: var(--font-size-default);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-big);
}

.read--view--bubble {
  width: var(--space-one);
  height: var(--space-one);
  border-radius: 50%;
  background: var(--color-woot);
}
</style>
