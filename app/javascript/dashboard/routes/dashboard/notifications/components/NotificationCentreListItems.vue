<template>
  <div class="notification-list-item--wrap">
    <div
      v-for="notificationItem in notifications"
      v-show="!isLoading"
      :key="notificationItem.id"
      class="notification-list--wrap"
      @click="() => onClickNotification(notificationItem)"
    >
      <div
        v-if="!notificationItem.read_at"
        class="notification--unread-indicator"
      ></div>
      <div v-else class="empty"></div>
      <div class="content-wrap">
        <div class="content-list-wrap">
          <div class="list-header-wrap">
            <div class="title-wrap">
              <span class="notification-title">
                {{
                  `#${
                    notificationItem.primary_actor
                      ? notificationItem.primary_actor.id
                      : 'deleted'
                  }`
                }}
              </span>
              <div class="notification-type--wrap">
                <span class="notification-type">
                  {{
                    $t(
                      `NOTIFICATIONS_PAGE.TYPE_LABEL.${notificationItem.notification_type}`
                    )
                  }}
                </span>
              </div>
            </div>
            <div class="thumbnail--column">
              <thumbnail
                v-if="notificationItem.primary_actor.meta.assignee"
                :src="notificationItem.primary_actor.meta.assignee.thumbnail"
                size="18px"
                :username="notificationItem.primary_actor.meta.assignee.name"
              />
            </div>
          </div>
          <div class="notification--message-title--wrap">
            <span class="notification--message-title text-truncate">
              {{ notificationItem.push_message_title }}
            </span>
          </div>
          <div class="timestamp--wrap">
            <span class="notification--created-at">
              {{ dynamicTime(notificationItem.created_at) }}
            </span>
          </div>
        </div>
      </div>
    </div>
    <empty-state
      v-if="showEmptyResult"
      :title="$t('NOTIFICATIONS_PAGE.LIST.404')"
    />
    <div v-if="isLoading" class="notifications--loader">
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
    isUpdating: {
      type: Boolean,
      default: false,
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
  display: flex;
  flex-direction: column;
  padding: var(--space-small) var(--space-slab);
  overflow: scroll;
  height: 100%;
}

.empty {
  display: flex;
  width: var(--space-small);
}

.notification-list--wrap {
  display: flex;
  flex-direction: row;
  align-items: center;
  padding: var(--space-slab);
  border-bottom: 1px solid var(--b-50);
}

.notification-list--wrap:hover {
  background: var(--b-100);
  border-radius: var(--border-radius-normal);
}

.content-wrap {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  margin-left: var(--space-slab);
  overflow: hidden;
  width: 100%;
}

.content-list-wrap {
  display: flex;
  flex-direction: column;
  width: 100%;
}

.list-header-wrap {
  display: flex;
  justify-content: space-between;
}

.title-wrap {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  flex-direction: row;
}

.notification-title {
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-black);
}

.notification-type--wrap {
  margin-left: var(--space-small);
}

.notification-type {
  font-size: var(--font-size-micro);
  color: var(--s-700);
  font-weight: var(--font-weight-medium);
  padding: var(--space-micro) var(--space-smaller);
  background: var(--s-50);
  border-radius: var(--border-radius-normal);
}

.notification--message-title--wrap {
  display: flex;
  justify-content: flex-start;
  width: 100%;
}

.notification--message-title {
  color: var(--color-body);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-normal);
}

.timestamp--wrap {
  margin-top: var(--space-smaller);
  color: var(--b-500);
  font-size: var(--font-size-micro);
  font-weight: var(--font-weight-bold);
}

.notification--unread-indicator {
  width: var(--space-small);
  height: var(--space-small);
  border-radius: var(--border-radius-rounded);
  background: var(--color-woot);
}
.notifications--loader {
  display: flex;
  align-items: center;
  justify-content: center;
  margin: var(--space-small);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
}
</style>
