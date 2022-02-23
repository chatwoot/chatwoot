<template>
  <div class="notification-list-item--wrap h-full flex-view ">
    <div
      v-for="notificationItem in notifications"
      v-show="!isLoading"
      :key="notificationItem.id"
      class="notification-list--wrap flex-view "
      @click="() => onClickNotification(notificationItem)"
    >
      <div
        v-if="!notificationItem.read_at"
        class="notification-unread--indicator"
      ></div>
      <div v-else class="empty flex-view"></div>
      <div class="notification-content--wrap w-full flex-space-between">
        <div class="flex-space-between">
          <div class="title-wrap flex-view ">
            <span class="notification-title">
              {{
                `#${
                  notificationItem.primary_actor
                    ? notificationItem.primary_actor.id
                    : 'deleted'
                }`
              }}
            </span>
            <span class="notification-type">
              {{
                $t(
                  `NOTIFICATIONS_PAGE.TYPE_LABEL.${notificationItem.notification_type}`
                )
              }}
            </span>
          </div>
          <div>
            <thumbnail
              v-if="notificationItem.primary_actor.meta.assignee"
              :src="notificationItem.primary_actor.meta.assignee.thumbnail"
              size="18px"
              :username="notificationItem.primary_actor.meta.assignee.name"
            />
          </div>
        </div>
        <div class="w-full flex-view ">
          <span class="notification-message text-truncate">
            {{ notificationItem.push_message_title }}
          </span>
        </div>
        <span class="timestamp">
          {{ dynamicTime(notificationItem.created_at) }}
        </span>
      </div>
    </div>
    <empty-state
      v-if="showEmptyResult"
      :title="$t('NOTIFICATIONS_PAGE.LIST.404')"
    />
    <div v-if="isLoading" class="notifications-loader flex-view">
      <spinner />
      <span>{{ $t('NOTIFICATIONS_PAGE.LIST.LOADING_MESSAGE') }}</span>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

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
      default: true,
    },
    onClickNotification: {
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
.notification-list-item--wrap {
  flex-direction: column;
  padding: var(--space-small) var(--space-slab);
  overflow: scroll;
}

.empty {
  width: var(--space-small);
}

.notification-list--wrap {
  flex-direction: row;
  align-items: center;
  padding: var(--space-slab);
  border-bottom: 1px solid var(--b-50);
}

.notification-list--wrap:hover {
  background: var(--b-100);
  border-radius: var(--border-radius-normal);
}

.notification-content--wrap {
  flex-direction: column;
  margin-left: var(--space-slab);
  overflow: hidden;
}

.title-wrap {
  align-items: center;
  justify-content: flex-start;
  flex-direction: row;
}

.notification-title {
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-black);
}

.notification-type {
  font-size: var(--font-size-micro);
  color: var(--s-700);
  font-weight: var(--font-weight-medium);
  padding: var(--space-micro) var(--space-smaller);
  margin-left: var(--space-small);
  background: var(--s-50);
  border-radius: var(--border-radius-normal);
}

.notification-message {
  color: var(--color-body);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-normal);
}

.timestamp {
  margin-top: var(--space-smaller);
  color: var(--b-500);
  font-size: var(--font-size-micro);
  font-weight: var(--font-weight-bold);
}

.notification-unread--indicator {
  width: var(--space-small);
  height: var(--space-small);
  border-radius: var(--border-radius-rounded);
  background: var(--color-woot);
}

.notifications-loader {
  align-items: center;
  justify-content: center;
  margin: var(--space-small);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
}
</style>
