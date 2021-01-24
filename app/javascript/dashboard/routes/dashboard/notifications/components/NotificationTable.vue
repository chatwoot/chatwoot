<template>
  <section class="notification--table-wrap">
    <woot-submit-button
      v-if="notificationMetadata.unreadCount"
      class="button nice success button--fixed-right-top"
      :button-text="$t('NOTIFICATIONS_PAGE.MARK_ALL_DONE')"
      :loading="isUpdating"
      @click="onMarkAllDoneClick"
    >
    </woot-submit-button>

    <table class="woot-table notifications-table">
      <tbody v-show="!isLoading">
        <tr
          v-for="notificationItem in notifications"
          :key="notificationItem.id"
          @click="() => onClickNotification(notificationItem)"
        >
          <td>
            <div class="notification--thumbnail">
              <thumbnail
                :src="notificationItem.primary_actor.meta.sender.thumbnail"
                size="36px"
                :username="notificationItem.primary_actor.meta.sender.name"
                :status="
                  notificationItem.primary_actor.meta.sender.availability_status
                "
              />
              <div>
                <h4 class="notification--name">
                  {{ `#${notificationItem.id}` }}
                </h4>
                <p class="notification--title">
                  {{ notificationItem.push_message_title }}
                </p>
              </div>
            </div>
          </td>
          <td>
            <span class="label">
              {{
                $t(
                  `NOTIFICATIONS_PAGE.TYPE_LABEL.${notificationItem.notification_type}`
                )
              }}
            </span>
          </td>
          <td>
            {{ dynamicTime(notificationItem.created_at) }}
          </td>
          <td>
            <div
              v-if="!notificationItem.read_at"
              class="notification--unread-indicator"
            />
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
import { mapGetters } from 'vuex';

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
    isUpdating: {
      type: Boolean,
      default: false,
    },
    onClickNotification: {
      type: Function,
      default: () => {},
    },
    onMarkAllDoneClick: {
      type: Function,
      default: () => {},
    },
  },
  computed: {
    ...mapGetters({
      notificationMetadata: 'notifications/getMeta',
    }),
    showEmptyResult() {
      return !this.isLoading && this.notifications.length === 0;
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/mixins';

.notification--name {
  font-size: var(--font-size-small);
  margin-bottom: 0;
}

.notification--title {
  font-size: var(--font-size-mini);
  margin: 0;
}

.notification--table-wrap {
  @include scroll-on-hover;
  flex: 1 1;
  height: 100%;
  padding: var(--space-normal);
}

.notifications-table {
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
        &.conversation-count-item {
          padding-left: var(--space-medium);
        }
      }
    }
  }
  .notification--thumbnail {
    display: flex;
    align-items: center;

    .user-thumbnail-box {
      margin-right: var(--space-small);
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

.notification--unread-indicator {
  width: var(--space-one);
  height: var(--space-one);
  border-radius: 50%;
  background: var(--color-woot);
}
</style>
