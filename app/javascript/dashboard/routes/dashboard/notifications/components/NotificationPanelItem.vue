<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import { dynamicTime } from 'shared/helpers/timeHelper';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    Thumbnail,
    NextButton,
  },
  props: {
    notificationItem: {
      type: Object,
      default: () => {},
    },
  },
  emits: ['openNotification'],
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
    dynamicTime,
    onClickOpenNotification() {
      this.$emit('openNotification', this.notificationItem);
    },
  },
};
</script>

<template>
  <div class="w-full">
    <NextButton
      link
      slate
      class="!w-full !h-auto"
      @click="onClickOpenNotification()"
    >
      <div
        class="flex-row items-center p-2.5 leading-[1.4] border-b border-solid border-slate-50 dark:border-slate-700 flex w-full hover:bg-slate-75 dark:hover:bg-slate-900 hover:rounded-md"
      >
        <div
          v-if="!notificationItem.read_at"
          class="w-2 h-2 rounded-full bg-woot-500"
        />
        <div v-else class="flex w-2" />
        <div
          class="flex-col ml-2.5 overflow-hidden w-full flex justify-between"
        >
          <div class="flex justify-between">
            <div class="flex items-center">
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
              <Thumbnail
                :src="notificationAssigneeThumbnail"
                size="16px"
                :username="notificationAssigneeName"
              />
            </div>
          </div>
          <div class="flex w-full">
            <span
              class="overflow-hidden font-normal text-slate-700 dark:text-slate-200 whitespace-nowrap text-ellipsis"
            >
              {{ notificationItem.push_message_title }}
            </span>
          </div>
          <span
            class="flex mt-1 font-semibold text-slate-500 dark:text-slate-400 text-xxs"
          >
            {{ dynamicTime(notificationItem.last_activity_at) }}
          </span>
        </div>
      </div>
    </NextButton>
  </div>
</template>
