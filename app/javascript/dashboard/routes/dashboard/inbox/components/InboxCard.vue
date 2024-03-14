<template>
  <div
    role="button"
    class="flex flex-col ltr:pl-5 rtl:pl-4 rtl:pr-5 ltr:pr-4 gap-2.5 py-3 w-full border-b border-slate-50 dark:border-slate-800/50 hover:bg-slate-25 dark:hover:bg-slate-800 cursor-pointer"
    :class="
      active
        ? 'bg-slate-25 dark:bg-slate-800 click-animation'
        : 'bg-white dark:bg-slate-900'
    "
    @contextmenu="openContextMenu($event)"
    @click="openConversation(notificationItem)"
  >
    <div
      class="flex flex-row justify-between relative items-center w-full gap-1.5"
    >
      <div
        v-if="isUnread"
        class="absolute ltr:-left-3.5 rtl:-right-3.5 flex w-2 h-2 rounded bg-woot-500 dark:bg-woot-500"
      />
      <Thumbnail
        v-if="assigneeMeta"
        :src="assigneeMeta.thumbnail"
        :username="assigneeMeta.name"
        size="16px"
      />
      <span
        class="flex-1 text-slate-900 dark:text-white text-sm overflow-hidden text-ellipsis whitespace-nowrap"
        :class="isUnread ? 'font-medium' : 'font-normal'"
      >
        {{ pushTitle }}
      </span>
    </div>

    <div
      ref="inboxCardInfo"
      class="flex flex-row justify-between items-center w-full gap-2"
    >
      <div
        v-if="snoozedUntilTime || hasLastSnoozed"
        class="flex flex-row flex-1 gap-1 items-center w-3/4"
      >
        <fluent-icon
          :icon="hasLastSnoozed ? 'snooze-timer' : 'sharp-timer'"
          type="outline"
          class="text-woot-500 dark:text-woot-500 flex-shrink-0"
          size="16"
        />
        <span
          class="text-woot-500 dark:text-woot-500 text-xs font-medium truncate"
        >
          {{ snoozedDisplayText }}
        </span>
      </div>
      <div v-else class="flex items-center flex-row justify-start gap-2 w-3/4">
        <inbox-card-info
          :inbox="inbox"
          :conversation-id="primaryActor.id"
          :conversation-labels="primaryActor.labels"
          :parent-element-width="inboxCardInfoElementWidth"
        />
        <div
          v-show="notificationTypes"
          class="flex flex-row items-center gap-0.5 w-fit"
        >
          <fluent-icon
            :icon="notificationTypeIcon"
            type="outline"
            class="text-woot-500 dark:text-woot-500"
            size="16"
          />
          <span
            class="font-medium text-woot-500 dark:text-woot-500 text-xs whitespace-nowrap"
          >
            {{ notificationTypes }}
          </span>
        </div>
      </div>
      <div class="flex items-center justify-end gap-2 w-1/4">
        <PriorityIcon :priority="primaryActor.priority" />
        <StatusIcon :status="primaryActor.status" />
        <span
          class="font-medium text-slate-500 dark:text-slate-400 text-xs whitespace-nowrap"
        >
          {{ lastActivityAt }}
        </span>
      </div>
    </div>
    <inbox-context-menu
      v-if="isContextMenuOpen"
      :context-menu-position="contextMenuPosition"
      :menu-items="menuItems"
      @close="closeContextMenu"
      @click="handleAction"
    />
  </div>
</template>

<script>
import PriorityIcon from './PriorityIcon.vue';
import StatusIcon from './StatusIcon.vue';
import InboxCardInfo from './InboxCardInfo.vue';
import InboxContextMenu from './InboxContextMenu.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import timeMixin from 'dashboard/mixins/time';
import {
  snoozedReopenTimeToTimestamp,
  shortenSnoozeTime,
} from 'dashboard/helper/snoozeHelpers';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { debounce } from '@chatwoot/utils';

const OBSERVER_DEBOUNCE_TIME = 100;

export default {
  components: {
    PriorityIcon,
    InboxContextMenu,
    StatusIcon,
    InboxCardInfo,
    Thumbnail,
  },
  mixins: [timeMixin],
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
  data() {
    return {
      isContextMenuOpen: false,
      contextMenuPosition: { x: null, y: null },
      resizeObserver: null,
      inboxCardInfoElementWidth: 0,
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
      return this.notificationItem?.push_message_body;
    },
    notificationTypes() {
      const usedTypes = ['CONVERSATION_MENTION', 'CONVERSATION_ASSIGNMENT'];
      const { notification_type: notificationType } = this.notificationItem;
      const upperCaseType = notificationType?.toUpperCase();

      return usedTypes.includes(upperCaseType)
        ? this.$t(`INBOX.TYPES.${upperCaseType}`)
        : '';
    },
    notificationTypeIcon() {
      const { notification_type: notificationType } = this.notificationItem;
      if (notificationType === 'conversation_mention') {
        return 'alternate-email';
      }
      if (notificationType === 'conversation_assignment') {
        return 'keyboard-double-arrow-right';
      }
      return '';
    },
    lastActivityAt() {
      const dynamicTime = this.dynamicTime(
        this.notificationItem?.last_activity_at
      );
      return this.shortTimestamp(dynamicTime);
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
      if (!snoozedUntil) {
        return null;
      }
      const timestamp = snoozedReopenTimeToTimestamp(snoozedUntil);
      return shortenSnoozeTime(this.dynamicTime(timestamp));
    },
    hasLastSnoozed() {
      return this.notificationItem?.meta?.last_snoozed_at;
    },
    snoozedDisplayText() {
      if (this.hasLastSnoozed) {
        return this.$t('INBOX.LIST.SNOOZED_ENDS');
      }
      if (this.snoozedUntilTime) {
        return this.$t('INBOX.LIST.SNOOZED_UNTIL', {
          time: this.shortTimestamp(this.snoozedUntilTime),
        });
      }
      return '';
    },
  },
  mounted() {
    this.$nextTick(() => {
      this.resizeObserver = new ResizeObserver(
        debounce(this.resizeObserverCallback, OBSERVER_DEBOUNCE_TIME, false)
      );
      if (this.$refs.inboxCardInfo) {
        this.resizeObserver.observe(this.$refs.inboxCardInfo);
      }
    });
  },
  unmounted() {
    if (this.resizeObserver) {
      this.resizeObserver.unobserve(this.$refs.inboxCardInfo);
      this.resizeObserver.disconnect();
    }
    this.closeContextMenu();
  },
  methods: {
    resizeObserverCallback(entries) {
      entries.forEach(entry => {
        this.inboxCardInfoElementWidth = entry.contentRect.width;
      });
    },
    openConversation(notification) {
      const {
        id,
        primary_actor_id: primaryActorId,
        primary_actor_type: primaryActorType,
        primary_actor: { inbox_id: inboxId },
        notification_type: notificationType,
      } = notification;

      if (this.$route.params.notification_id !== id) {
        this.$track(INBOX_EVENTS.OPEN_CONVERSATION_VIA_INBOX, {
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
      this.$emit('context-menu-close');
    },
    openContextMenu(e) {
      this.closeContextMenu();
      e.preventDefault();
      this.contextMenuPosition = {
        x: e.pageX || e.clientX,
        y: e.pageY || e.clientY,
      };
      this.isContextMenuOpen = true;
      this.$emit('context-menu-open');
    },
    handleAction(key) {
      switch (key) {
        case 'mark_as_read':
          this.$emit('mark-notification-as-read', this.notificationItem);
          break;
        case 'mark_as_unread':
          this.$emit('mark-notification-as-unread', this.notificationItem);
          break;
        case 'delete':
          this.$emit('delete-notification', this.notificationItem);
          break;
        default:
      }
    },
  },
};
</script>

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
