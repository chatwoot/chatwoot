<script>
import PriorityIcon from './PriorityIcon.vue';
import StatusIcon from './StatusIcon.vue';
import InboxNameAndId from './InboxNameAndId.vue';
import InboxContextMenu from './InboxContextMenu.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import { snoozedReopenTime } from 'dashboard/helper/snoozeHelpers';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useTrack } from 'dashboard/composables';

export default {
  components: {
    PriorityIcon,
    InboxContextMenu,
    StatusIcon,
    InboxNameAndId,
    Thumbnail,
  },
  props: {
    notificationItem: {
      type: Object,
      default: () => {},
    },
    active: {
      type: Boolean,
      default: false,
    },
  },
  emits: [
    'contextMenuClose',
    'contextMenuOpen',
    'markNotificationAsRead',
    'markNotificationAsUnRead',
    'deleteNotification',
  ],
  data() {
    return {
      isContextMenuOpen: false,
      contextMenuPosition: { x: null, y: null },
    };
  },
  computed: {
    primaryActor() {
      return this.notificationItem?.primary_actor;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](
        this.primaryActor.inbox_id
      );
    },
    isUnread() {
      return !this.notificationItem?.read_at;
    },
    meta() {
      return this.primaryActor?.meta;
    },
    assigneeMeta() {
      return this.meta?.assignee;
    },
    pushTitle() {
      return this.$t(
        `INBOX.TYPES.${this.notificationItem.notification_type.toUpperCase()}`
      );
    },
    lastActivityAt() {
      const time = dynamicTime(this.notificationItem?.last_activity_at);
      return shortTimestamp(time, true);
    },
    menuItems() {
      const items = [
        {
          key: 'delete',
          label: this.$t('INBOX.MENU_ITEM.DELETE'),
        },
      ];

      if (!this.isUnread) {
        items.push({
          key: 'mark_as_unread',
          label: this.$t('INBOX.MENU_ITEM.MARK_AS_UNREAD'),
        });
      } else {
        items.push({
          key: 'mark_as_read',
          label: this.$t('INBOX.MENU_ITEM.MARK_AS_READ'),
        });
      }
      return items;
    },
    snoozedUntilTime() {
      const { snoozed_until: snoozedUntil } = this.notificationItem;
      return snoozedUntil;
    },
    snoozedDisplayText() {
      if (this.snoozedUntilTime) {
        return `${this.$t('INBOX.LIST.SNOOZED_UNTIL')} ${snoozedReopenTime(
          this.snoozedUntilTime
        )}`;
      }
      return '';
    },
  },
  unmounted() {
    this.closeContextMenu();
  },
  methods: {
    openConversation(notification) {
      const {
        id,
        primary_actor_id: primaryActorId,
        primary_actor_type: primaryActorType,
        primary_actor: { inbox_id: inboxId },
        notification_type: notificationType,
      } = notification;

      if (this.$route.params.notification_id !== id) {
        useTrack(INBOX_EVENTS.OPEN_CONVERSATION_VIA_INBOX, {
          notificationType,
        });

        this.$store.dispatch('notifications/read', {
          id,
          primaryActorId,
          primaryActorType,
          unreadCount: this.meta.unreadCount,
        });

        this.$router.push({
          name: 'inbox_view_conversation',
          params: { inboxId, notification_id: id },
        });
      }
    },
    closeContextMenu() {
      this.isContextMenuOpen = false;
      this.contextMenuPosition = { x: null, y: null };
      this.$emit('contextMenuClose');
    },
    openContextMenu(e) {
      this.closeContextMenu();
      e.preventDefault();
      this.contextMenuPosition = {
        x: e.pageX || e.clientX,
        y: e.pageY || e.clientY,
      };
      this.isContextMenuOpen = true;
      this.$emit('contextMenuOpen');
    },
    handleAction(key) {
      switch (key) {
        case 'mark_as_read':
          this.$emit('markNotificationAsRead', this.notificationItem);
          break;
        case 'mark_as_unread':
          this.$emit('markNotificationAsUnRead', this.notificationItem);
          break;
        case 'delete':
          this.$emit('deleteNotification', this.notificationItem);
          break;
        default:
      }
    },
  },
};
</script>

<template>
  <div
    role="button"
    class="flex flex-col ltr:pl-5 rtl:pl-3 rtl:pr-5 ltr:pr-3 gap-2.5 py-3 w-full border-b border-slate-50 dark:border-slate-800/50 hover:bg-slate-25 dark:hover:bg-slate-800 cursor-pointer"
    :class="
      active
        ? 'bg-slate-25 dark:bg-slate-800 click-animation'
        : 'bg-white dark:bg-slate-900'
    "
    @contextmenu="openContextMenu($event)"
    @click="openConversation(notificationItem)"
  >
    <div class="relative flex items-center justify-between w-full">
      <div
        v-if="isUnread"
        class="absolute ltr:-left-3.5 rtl:-right-3.5 flex w-2 h-2 rounded bg-woot-500 dark:bg-woot-500"
      />
      <InboxNameAndId :inbox="inbox" :conversation-id="primaryActor.id" />

      <div class="flex gap-2">
        <PriorityIcon :priority="primaryActor.priority" />
        <StatusIcon :status="primaryActor.status" />
      </div>
    </div>

    <div class="flex flex-row items-center justify-between w-full gap-2">
      <Thumbnail
        v-if="assigneeMeta"
        :src="assigneeMeta.thumbnail"
        :username="assigneeMeta.name"
        size="16px"
      />
      <span
        class="flex-1 overflow-hidden text-sm text-slate-800 dark:text-slate-50 text-ellipsis whitespace-nowrap"
        :class="isUnread ? 'font-medium' : 'font-normal'"
      >
        {{ pushTitle }}
      </span>
      <span
        class="text-xs font-medium text-slate-600 dark:text-slate-300 whitespace-nowrap"
      >
        {{ lastActivityAt }}
      </span>
    </div>
    <div v-if="snoozedUntilTime" class="flex items-center">
      <span class="text-xs font-medium text-woot-500 dark:text-woot-500">
        {{ snoozedDisplayText }}
      </span>
    </div>
    <InboxContextMenu
      v-if="isContextMenuOpen"
      :context-menu-position="contextMenuPosition"
      :menu-items="menuItems"
      @close="closeContextMenu"
      @select-action="handleAction"
    />
  </div>
</template>

<style scoped>
.click-animation {
  animation: click-animation 0.3s ease-in-out;
}

@keyframes click-animation {
  0% {
    transform: scale(1);
  }

  50% {
    transform: scale(0.99);
  }

  100% {
    transform: scale(1);
  }
}
</style>
