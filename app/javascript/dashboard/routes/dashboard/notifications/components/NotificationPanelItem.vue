<template>
  <div class="w-full">
    <woot-button
      size="expanded"
      color-scheme="secondary"
      variant="link"
      class="w-full"
      @click="onClickOpenNotification()"
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
            <div v-if="hasNotificationAssignee">
              <thumbnail
                :src="notificationAssigneeThumbnail"
                size="16px"
                :username="notificationAssigneeName"
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
            {{ dynamicTime(notificationItem.last_activity_at) }}
          </span>
        </div>
      </div>
    </woot-button>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import timeMixin from 'dashboard/mixins/time';

export default {
  components: {
    Thumbnail,
  },
  mixins: [timeMixin],
  props: {
    notificationItem: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    notificationAssignee() {
      const { primary_actor: primaryActor } = this.notificationItem;
      return primaryActor?.meta?.assignee;
    },
    hasNotificationAssignee() {
      return !!this.notificationAssignee;
    },
    notificationAssigneeName() {
      return this.notificationAssignee?.name || '';
    },
    notificationAssigneeThumbnail() {
      return this.notificationAssignee?.thumbnail || '';
    },
  },
  methods: {
    onClickOpenNotification() {
      this.$emit('open-notification', this.notificationItem);
    },
  },
};
</script>
