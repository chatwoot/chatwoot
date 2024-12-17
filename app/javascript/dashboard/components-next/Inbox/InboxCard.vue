<script setup>
import { computed, ref, onBeforeMount } from 'vue';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { useI18n } from 'vue-i18n';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import {
  NOTIFICATION_TYPES_MAPPING,
  NOTIFICATION_TYPES_WITHOUT_MESSAGE,
} from 'dashboard/routes/dashboard/inbox/helpers/InboxViewHelpers';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import CardPriorityIcon from 'dashboard/components-next/Conversation/ConversationCard/CardPriorityIcon.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/ConversationCard/SLACardLabel.vue';
import InboxContextMenu from 'dashboard/routes/dashboard/inbox/components/InboxContextMenu.vue';

const props = defineProps({
  inboxItem: {
    type: Object,
    default: () => {},
  },
  stateInbox: {
    type: Object,
    default: () => {},
  },
});

const emit = defineEmits([
  'click',
  'contextMenuOpen',
  'contextMenuClose',
  'markNotificationAsRead',
  'markNotificationAsUnRead',
  'deleteNotification',
]);

const { t } = useI18n();

const isContextMenuOpen = ref(false);
const contextMenuPosition = ref({ x: null, y: null });
const slaCardLabel = ref(null);

const primaryActor = computed(() => props.inboxItem?.primaryActor);
const meta = computed(() => primaryActor.value?.meta);
const assigneeMeta = computed(() => meta.value?.assignee);
const isUnread = computed(() => !props.inboxItem?.readAt);

const menuItems = computed(() => [
  { key: 'delete', label: t('INBOX.MENU_ITEM.DELETE') },
  {
    key: isUnread.value ? 'mark_as_read' : 'mark_as_unread',
    label: t(`INBOX.MENU_ITEM.MARK_AS_${isUnread.value ? 'READ' : 'UNREAD'}`),
  },
]);

const formattedMessage = computed(() => {
  const { notificationType = '' } = props.inboxItem || {};
  const classes = {
    emphasis: 'text-sm font-medium text-n-slate-12',
    normal: 'text-sm font-normal text-n-slate-11',
  };

  // Handle cases without push message body
  if (NOTIFICATION_TYPES_WITHOUT_MESSAGE.includes(notificationType)) {
    return `<span class="${classes.emphasis}">${meta.value?.sender?.name}:</span> 
            <span class="${classes.normal}">${primaryActor.value?.messages[0]?.content || t('INBOX.NO_CONTENT')}</span>`;
  }

  // Handle push messages
  const message = props.inboxItem?.pushMessageBody || '';
  const formattedContent = message.replace(
    /^([^:]+):|@(\w+)/g,
    (match, name, mention) => {
      if (name) {
        return `<span class="${classes.emphasis}">${name}:</span>`;
      }
      return `<span class="${classes.emphasis}">@${mention}</span>`;
    }
  );

  return `<span class="${classes.normal}">${formattedContent}</span>`;
});

const notificationDetails = computed(() => {
  const type = props.inboxItem?.notificationType?.toUpperCase() || '';
  const [icon = '', color = 'text-n-blue-text'] =
    NOTIFICATION_TYPES_MAPPING[type] || [];
  return {
    text: NOTIFICATION_TYPES_MAPPING[type] ? t(`INBOX.TYPES_NEXT.${type}`) : '',
    icon,
    color,
  };
});

const inbox = computed(() => props.stateInbox);

const inboxName = computed(() => inbox.value?.name);

const inboxIcon = computed(() => {
  const { phoneNumber, channelType } = inbox.value;
  return getInboxIconByType(channelType, phoneNumber);
});

const conversationPriority = computed(() => primaryActor.value?.priority || '');

const lastActivityAt = computed(() => {
  const timestamp = props.inboxItem?.lastActivityAt;
  return timestamp ? shortTimestamp(dynamicTime(timestamp)) : '';
});

const hasSlaThreshold = computed(() => {
  return slaCardLabel.value?.hasSlaThreshold && primaryActor.value?.slaPolicyId;
});

const snoozedUntilTime = computed(() => {
  const { snoozedUntil } = props.inboxItem;
  return snoozedUntil;
});

const hasLastSnoozed = computed(() => {
  const { lastSnoozedAt = '' } = props.inboxItem?.meta || {};
  return lastSnoozedAt;
});

const contextMenuActions = {
  closeContextMenu: () => {
    isContextMenuOpen.value = false;
    contextMenuPosition.value = { x: null, y: null };
    emit('contextMenuClose');
  },

  openContextMenu: e => {
    e.preventDefault();
    contextMenuPosition.value = {
      x: e.pageX || e.clientX,
      y: e.pageY || e.clientY,
    };
    isContextMenuOpen.value = true;
    emit('contextMenuOpen');
  },

  handleAction: key => {
    const actions = {
      mark_as_read: () => emit('markNotificationAsRead', props.inboxItem),
      mark_as_unread: () => emit('markNotificationAsUnRead', props.inboxItem),
      delete: () => emit('deleteNotification', props.inboxItem),
    };
    actions[key]?.();
  },
};

onBeforeMount(contextMenuActions.closeContextMenu);

const onCardClick = () => {
  emit('click');
};
</script>

<template>
  <div
    role="button"
    class="flex flex-col w-full gap-2 p-3 transition-all duration-300 ease-in-out cursor-pointer"
    @contextmenu="contextMenuActions.openContextMenu($event)"
    @click="onCardClick"
  >
    <div class="flex items-start gap-2">
      <Avatar
        :name="assigneeMeta.name"
        :src="assigneeMeta.thumbnail"
        :size="20"
        :status="assigneeMeta.availabilityStatus"
        rounded-full
        class="mt-1"
      />
      <p v-dompurify-html="formattedMessage" class="mb-0 line-clamp-2" />
    </div>
    <div class="flex items-center justify-between h-6 gap-2">
      <div class="flex items-center flex-1 min-w-0 gap-1">
        <div
          v-if="snoozedUntilTime || hasLastSnoozed"
          class="flex items-center w-full min-w-0 gap-2 ltr:pl-1 rtl:pr-1"
        >
          <Icon
            :icon="
              !hasLastSnoozed
                ? 'i-lucide-alarm-clock-plus'
                : 'i-lucide-alarm-clock-off'
            "
            class="flex-shrink-0 size-4 text-n-blue-text"
          />
          <span class="text-xs font-medium truncate text-n-blue-text">
            {{
              !hasLastSnoozed
                ? t('INBOX.TYPES_NEXT.SNOOZED_NOTIFICATION')
                : t('INBOX.TYPES_NEXT.SNOOZED_NOTIFICATION_LAST')
            }}
          </span>
        </div>
        <div
          v-else-if="notificationDetails.text"
          class="flex items-center w-full min-w-0 gap-2 ltr:pl-1 rtl:pr-1"
        >
          <Icon
            :icon="notificationDetails.icon"
            :class="notificationDetails.color"
            class="flex-shrink-0 size-4"
          />
          <span
            class="text-xs font-medium truncate"
            :class="notificationDetails.color"
          >
            {{ notificationDetails.text }}
          </span>
        </div>
      </div>
      <div class="flex items-center flex-shrink-0 gap-2">
        <SLACardLabel
          v-show="hasSlaThreshold"
          ref="slaCardLabel"
          :conversation="primaryActor"
          class="[&>span]:text-xs"
        />
        <div v-if="hasSlaThreshold" class="w-px h-3 rounded-sm bg-n-slate-4" />
        <CardPriorityIcon
          v-if="conversationPriority"
          :priority="conversationPriority"
          class="[&>svg]:size-4"
        />
        <div
          v-if="inboxIcon"
          v-tooltip.left="inboxName"
          class="flex items-center justify-center flex-shrink-0 rounded-full bg-n-alpha-2 size-4"
        >
          <Icon
            :icon="inboxIcon"
            class="flex-shrink-0 text-n-slate-11 size-2.5"
          />
        </div>
        <span class="text-sm text-n-slate-10">
          {{ lastActivityAt }}
        </span>
      </div>
    </div>
    <InboxContextMenu
      v-if="isContextMenuOpen"
      :context-menu-position="contextMenuPosition"
      :menu-items="menuItems"
      @close="contextMenuActions.closeContextMenu"
      @select-action="contextMenuActions.handleAction"
    />
  </div>
</template>
