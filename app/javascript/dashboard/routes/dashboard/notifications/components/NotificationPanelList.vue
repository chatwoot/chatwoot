<template>
  <div class="notification-list-item--wrap h-full flex-view ">
    <woot-button
      v-for="notificationItem in notifications"
      v-show="!isLoading"
      :key="notificationItem.id"
      size="expanded"
      color-scheme="secondary"
      variant="link"
      @click="() => onClickNotification(notificationItem)"
    >
      <div class="notification-list--wrap flex-view w-full">
        <div
          v-if="!notificationItem.read_at"
          class="notification-unread--indicator"
        />
        <div v-else class="empty flex-view" />
        <div class="notification-content--wrap w-full flex-space-between">
          <div class="flex-space-between">
            <div class="title-wrap flex-view ">
              <span class="notification-title">
                {{
                  `#${
                    notificationItem.primary_actor
                      ? notificationItem.primary_actor.id
                      : $t(`NOTIFICATIONS_PAGE.DELETE_TITLE`)
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
                size="16px"
                :username="notificationItem.primary_actor.meta.assignee.name"
              />
            </div>
          </div>
          <div class="w-full flex-view ">
            <span class="notification-message text-truncate">
              {{ notificationItem.push_message_title }}
            </span>
          </div>
          <span class="timestamp flex-view">
            {{ dynamicTime(notificationItem.created_at) }}
          </span>
        </div>
      </div>
    </woot-button>
    <empty-state
      v-if="showEmptyResult"
      :title="$t('NOTIFICATIONS_PAGE.UNREAD_NOTIFICATION.EMPTY_MESSAGE')"
    />
    <woot-button
      v-if="!isLoading && inLastPage"
      size="medium"
      variant="clear"
      color-scheme="primary"
      class-names="action-button"
      @click="openNotificationPage"
    >
      {{ $t('NOTIFICATIONS_PAGE.UNREAD_NOTIFICATION.ALL_NOTIFICATIONS') }}
    </woot-button>
    <div v-if="isLoading" class="notifications-loader flex-view">
      <spinner />
      <span>{{
        $t('NOTIFICATIONS_PAGE.UNREAD_NOTIFICATION.LOADING_UNREAD_MESSAGE')
      }}</span>
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
    inLastPage: {
      type: Boolean,
      default: false,
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
  methods: {
    openNotificationPage() {
      if (this.$route.name !== 'notifications_index') {
        this.$router.push({
          name: 'notifications_index',
        });
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.flex-view {
  display: flex;
}

.flex-space-between {
  display: flex;
  justify-content: space-between;
}

.notification-list-item--wrap {
  flex-direction: column;
  padding: var(--space-small) var(--space-slab);
  overflow: auto;
}

.empty {
  width: var(--space-small);
}

.notification-list--wrap {
  flex-direction: row;
  align-items: center;
  padding: var(--space-slab);
  line-height: 1.4;
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
}

.notification-title {
  font-weight: var(--font-weight-black);
}

.notification-type {
  font-size: var(--font-size-micro);
  padding: var(--space-micro) var(--space-smaller);
  margin: 0 var(--space-small);
  background: var(--s-50);
  border-radius: var(--border-radius-normal);
}

.notification-message {
  color: var(--color-body);
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

.action-button {
  margin-top: var(--space-slab);
}

.notifications-loader {
  align-items: center;
  justify-content: center;
  margin: var(--space-larger) var(--space-small);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
}
</style>
