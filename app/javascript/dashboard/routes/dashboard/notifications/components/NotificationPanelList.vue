<template>
  <div class="flex-col py-2 px-2.5 overflow-auto h-full flex">
    <woot-button
      v-for="notificationItem in notifications"
      v-show="!isLoading"
      :key="notificationItem.id"
      size="expanded"
      color-scheme="secondary"
      variant="link"
      @click="() => onClickNotification(notificationItem)"
    >
      <div
        class="flex-row items-center p-2.5 leading-[1.4] border-b border-solid border-slate-50 dark:border-slate-700 flex w-full hover:bg-slate-75 dark:hover:bg-slate-900 hover:rounded-md"
      >
        <div
          v-if="!notificationItem.read_at"
          class="w-2 h-2 rounded-full bg-woot-500"
        />
        <div v-else class="w-2 flex" />
        <div
          class="flex-col ml-2.5 overflow-hidden w-full flex justify-between"
        >
          <div class="flex justify-between">
            <div class="items-center flex">
              <span class="font-bold text-slate-800 dark:text-slate-100">
                {{
                  `#${
                    notificationItem.primary_actor
                      ? notificationItem.primary_actor.id
                      : $t(`NOTIFICATIONS_PAGE.DELETE_TITLE`)
                  }`
                }}
              </span>
              <span
                class="text-xxs p-0.5 px-1 my-0 mx-2 bg-slate-50 dark:bg-slate-700 rounded-md"
              >
                {{
                  $t(
                    `NOTIFICATIONS_PAGE.TYPE_LABEL.${notificationItem.notification_type}`
                  )
                }}
              </span>
            </div>
            <div>
              <thumbnail
                v-if="hasAssignee(notificationItem)"
                :src="notificationItem.primary_actor.meta.assignee.thumbnail"
                size="16px"
                :username="notificationItem.primary_actor.meta.assignee.name"
              />
            </div>
          </div>
          <div class="w-full flex">
            <span
              class="text-slate-700 dark:text-slate-200 font-normal overflow-hidden whitespace-nowrap text-ellipsis"
            >
              {{ notificationItem.push_message_title }}
            </span>
          </div>
          <span
            class="mt-1 text-slate-500 dark:text-slate-400 text-xxs font-semibold flex"
          >
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
      size="expanded"
      variant="clear"
      color-scheme="primary"
      class-names="mt-3"
      @click="openNotificationPage"
    >
      {{ $t('NOTIFICATIONS_PAGE.UNREAD_NOTIFICATION.ALL_NOTIFICATIONS') }}
    </woot-button>
    <div
      v-if="isLoading"
      class="items-center justify-center my-12 mx-2 text-sm font-medium flex"
    >
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
    hasAssignee(notification) {
      return notification.primary_actor.meta?.assignee;
    },
  },
};
</script>
