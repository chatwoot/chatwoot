<script setup>
import { computed, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import Avatar from 'next/avatar/Avatar.vue';
import MessagePreview from './MessagePreview.vue';
import InboxName from '../InboxName.vue';
import ConversationContextMenu from './contextMenu/Index.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import CardLabels from './conversationCardComponents/CardLabels.vue';
import PriorityMark from './PriorityMark.vue';
import SLACardLabel from './components/SLACardLabel.vue';
import ContextMenu from 'dashboard/components/ui/ContextMenu.vue';
import VoiceCallStatus from './VoiceCallStatus.vue';

const props = defineProps({
  activeLabel: { type: String, default: '' },
  chat: { type: Object, default: () => ({}) },
  hideInboxName: { type: Boolean, default: false },
  hideThumbnail: { type: Boolean, default: false },
  teamId: { type: [String, Number], default: 0 },
  foldersId: { type: [String, Number], default: 0 },
  showAssignee: { type: Boolean, default: false },
  conversationType: { type: String, default: '' },
  selected: { type: Boolean, default: false },
  compact: { type: Boolean, default: false },
  enableContextMenu: { type: Boolean, default: false },
  allowedContextMenuOptions: { type: Array, default: () => [] },
});

const emit = defineEmits([
  'contextMenuToggle',
  'assignAgent',
  'assignLabel',
  'removeLabel',
  'assignTeam',
  'markAsUnread',
  'markAsRead',
  'assignPriority',
  'updateConversationStatus',
  'deleteConversation',
  'selectConversation',
  'deSelectConversation',
]);

const router = useRouter();
const store = useStore();

const hovered = ref(false);
const showContextMenu = ref(false);
const contextMenu = ref({
  x: null,
  y: null,
});

const currentChat = useMapGetter('getSelectedChat');
const inboxesList = useMapGetter('inboxes/getInboxes');
const activeInbox = useMapGetter('getSelectedInbox');
const accountId = useMapGetter('getCurrentAccountId');

const chatMetadata = computed(() => props.chat.meta || {});

const assignee = computed(() => chatMetadata.value.assignee || {});

const assigneeFirstName = computed(() => {
  const name = assignee.value.name;
  if (!name) return '';
  return name.split(' ')[0];
});

const senderId = computed(() => chatMetadata.value.sender?.id);

const currentContact = computed(() => {
  return senderId.value
    ? store.getters['contacts/getContact'](senderId.value)
    : {};
});

const isActiveChat = computed(() => {
  return currentChat.value.id === props.chat.id;
});

const unreadCount = computed(() => props.chat.unread_count);

const hasUnread = computed(() => unreadCount.value > 0);

const isInboxNameVisible = computed(() => !activeInbox.value);

const lastMessageInChat = computed(() => getLastMessage(props.chat));

const voiceCallData = computed(() => ({
  status: props.chat.additional_attributes?.call_status,
  direction: props.chat.additional_attributes?.call_direction,
}));

const inboxId = computed(() => props.chat.inbox_id);

const inbox = computed(() => {
  return inboxId.value ? store.getters['inboxes/getInbox'](inboxId.value) : {};
});

const isAWhatsAppChannel = computed(() => {
  if (!inbox.value) return false;
  const channelType = inbox.value.channel_type || inbox.value.channelType;
  const medium = inbox.value.medium || '';
  return (
    channelType === 'Channel::Whatsapp' ||
    (channelType === 'Channel::TwilioSms' && medium === 'whatsapp')
  );
});

const formattedPhoneNumber = computed(() => {
  const name = currentContact.value.name || '';
  const phone = currentContact.value.phone_number;

  if (
    isAWhatsAppChannel.value &&
    phone &&
    name !== phone &&
    !name.includes(phone)
  ) {
    let cleanPhone = phone.replace(/^\+/, '');
    if (cleanPhone.startsWith('2')) {
      cleanPhone = cleanPhone.substring(1);
    }
    return cleanPhone;
  }

  return null;
});

const showInboxName = computed(() => {
  return (
    !props.hideInboxName &&
    isInboxNameVisible.value &&
    inboxesList.value.length > 1
  );
});

const showMetaSection = computed(() => {
  return (
    showInboxName.value ||
    (props.showAssignee && assignee.value.name) ||
    props.chat.priority
  );
});

const hasSlaPolicyId = computed(() => props.chat?.sla_policy_id);

const showLabelsSection = computed(() => {
  return props.chat.labels?.length > 0 || hasSlaPolicyId.value;
});

const messagePreviewClass = computed(() => {
  return [
    hasUnread.value ? 'font-semibold text-n-slate-12' : 'text-n-slate-9',
    !props.compact && hasUnread.value ? 'ltr:pr-4 rtl:pl-4' : '',
    props.compact && hasUnread.value ? 'ltr:pr-6 rtl:pl-6' : '',
  ];
});

const conversationPath = computed(() => {
  return frontendURL(
    conversationUrl({
      accountId: accountId.value,
      activeInbox: activeInbox.value,
      id: props.chat.id,
      label: props.activeLabel,
      teamId: props.teamId,
      conversationType: props.conversationType,
      foldersId: props.foldersId,
    })
  );
});

const onCardClick = e => {
  const path = conversationPath.value;
  if (!path) return;

  // Handle Ctrl/Cmd + Click for new tab
  if (e.metaKey || e.ctrlKey) {
    e.preventDefault();
    window.open(
      `${window.chatwootConfig.hostURL}${path}`,
      '_blank',
      'noopener,noreferrer'
    );
    return;
  }

  // Skip if already active
  if (isActiveChat.value) return;

  router.push({ path });
};

const onThumbnailHover = () => {
  hovered.value = !props.hideThumbnail;
};

const onThumbnailLeave = () => {
  hovered.value = false;
};

const onSelectConversation = checked => {
  if (checked) {
    emit('selectConversation', props.chat.id, inbox.value.id);
  } else {
    emit('deSelectConversation', props.chat.id, inbox.value.id);
  }
};

const openContextMenu = e => {
  if (!props.enableContextMenu) return;
  e.preventDefault();
  emit('contextMenuToggle', true);
  contextMenu.value.x = e.pageX || e.clientX;
  contextMenu.value.y = e.pageY || e.clientY;
  showContextMenu.value = true;
};

const closeContextMenu = () => {
  emit('contextMenuToggle', false);
  showContextMenu.value = false;
  contextMenu.value.x = null;
  contextMenu.value.y = null;
};

const onUpdateConversation = (status, snoozedUntil) => {
  closeContextMenu();
  emit('updateConversationStatus', props.chat.id, status, snoozedUntil);
};

const onAssignAgent = agent => {
  emit('assignAgent', agent, [props.chat.id]);
  closeContextMenu();
};

const onAssignLabel = label => {
  emit('assignLabel', [label.title], [props.chat.id]);
};

const onRemoveLabel = label => {
  emit('removeLabel', [label.title], [props.chat.id]);
};

const onAssignTeam = team => {
  emit('assignTeam', team, props.chat.id);
  closeContextMenu();
};

const markAsUnread = () => {
  emit('markAsUnread', props.chat.id);
  closeContextMenu();
};

const markAsRead = () => {
  emit('markAsRead', props.chat.id);
  closeContextMenu();
};

const assignPriority = priority => {
  emit('assignPriority', priority, props.chat.id);
  closeContextMenu();
};

const deleteConversation = () => {
  emit('deleteConversation', props.chat.id);
  closeContextMenu();
};
</script>

<template>
  <div
    class="relative flex items-start flex-grow-0 flex-shrink-0 w-auto max-w-full py-0 border-transparent border-solid cursor-pointer conversation hover:bg-n-alpha-1 dark:hover:bg-n-alpha-3 group transition-all duration-150"
    :class="{
      'active animate-card-select bg-n-background border-l-[3px] !border-l-n-brand':
        isActiveChat,
      'bg-n-slate-2': selected,
      'px-0': compact,
      'px-3': !compact,
      'border-l-[3px] border-l-transparent': !isActiveChat,
    }"
    @click="onCardClick"
    @contextmenu="openContextMenu($event)"
  >
    <div
      class="relative"
      @mouseenter="onThumbnailHover"
      @mouseleave="onThumbnailLeave"
    >
      <Avatar
        v-if="!hideThumbnail"
        :name="currentContact.name"
        :src="currentContact.thumbnail"
        :size="32"
        :status="currentContact.availability_status"
        :class="!showInboxName ? 'mt-4' : 'mt-8'"
        hide-offline-status
        rounded-full
      >
        <template #overlay="{ size }">
          <label
            v-if="hovered || selected"
            class="flex items-center justify-center rounded-full cursor-pointer absolute inset-0 z-10 backdrop-blur-[2px]"
            :style="{ width: `${size}px`, height: `${size}px` }"
            @click.stop
          >
            <input
              :value="selected"
              :checked="selected"
              class="!m-0 cursor-pointer"
              type="checkbox"
              @change="onSelectConversation($event.target.checked)"
            />
          </label>
        </template>
      </Avatar>
    </div>
    <div class="px-0 py-3 border-b flex-1 border-n-weak min-w-0">
      <div
        v-if="showMetaSection"
        class="flex items-center min-w-0 gap-1"
        :class="{
          'ltr:ml-2 rtl:mr-2': !compact,
          'mx-2': compact,
        }"
      >
        <InboxName v-if="showInboxName" :inbox="inbox" class="flex-1 min-w-0" />
        <div
          class="flex items-center gap-2 flex-shrink-0"
          :class="{
            'flex-1 justify-between': !showInboxName,
          }"
        >
          <span
            v-if="showAssignee && assignee.name"
            class="text-n-slate-11 text-xs font-medium leading-3 py-0.5 px-0 inline-flex items-center truncate"
          >
            <fluent-icon icon="person" size="12" class="text-n-slate-11" />
            {{ assigneeFirstName }}
          </span>
          <PriorityMark :priority="chat.priority" class="flex-shrink-0" />
        </div>
      </div>
      <div
        class="flex items-center my-0 mx-2 pt-0.5 flex-1 min-w-0 ltr:pr-16 rtl:pl-16"
      >
        <div
          v-if="formattedPhoneNumber"
          class="inline-flex items-stretch border border-[#BBDEFB] dark:border-[#1E40AF] rounded max-w-full overflow-hidden shadow-sm"
        >
          <h4
            class="conversation--user text-xs px-2 py-0.5 capitalize text-ellipsis overflow-hidden whitespace-nowrap min-w-0 bg-[#E3F2FD] dark:bg-[#1E3A8A] text-[#1565C0] dark:text-[#93C5FD] font-bold"
          >
            {{ currentContact.name }}
          </h4>
          <span
            class="px-2 py-0.5 text-[10px] ltr:border-l rtl:border-r border-[#BBDEFB] dark:border-[#1E40AF] flex-shrink-0 flex items-center bg-[#E8F5E9] dark:bg-[#064E3B] text-[#2E7D32] dark:text-[#6EE7B7] font-bold"
            dir="ltr"
          >
            {{ formattedPhoneNumber }}
          </span>
        </div>
        <h4
          v-else
          class="conversation--user text-sm capitalize text-ellipsis overflow-hidden whitespace-nowrap min-w-0"
          :class="
            hasUnread
              ? 'font-bold text-n-slate-12'
              : 'font-medium text-n-slate-12'
          "
        >
          {{ currentContact.name }}
        </h4>
      </div>
      <VoiceCallStatus
        v-if="voiceCallData.status"
        key="voice-status-row"
        :status="voiceCallData.status"
        :direction="voiceCallData.direction"
        :message-preview-class="messagePreviewClass"
      />
      <MessagePreview
        v-else-if="lastMessageInChat"
        key="message-preview"
        :message="lastMessageInChat"
        dir="auto"
        class="my-0 mx-2 leading-6 h-6 flex-1 min-w-0 text-xs"
        :class="messagePreviewClass"
      />
      <p
        v-else
        key="no-messages"
        class="text-n-slate-11 text-xs my-0 mx-2 leading-6 h-6 flex-1 min-w-0 overflow-hidden text-ellipsis whitespace-nowrap"
        :class="messagePreviewClass"
      >
        <fluent-icon
          size="16"
          class="-mt-0.5 align-middle inline-block text-n-slate-10"
          icon="info"
        />
        <span class="mx-0.5">
          {{ $t(`CHAT_LIST.NO_MESSAGES`) }}
        </span>
      </p>
      <div
        class="absolute flex flex-col ltr:right-3 rtl:left-3"
        :class="showMetaSection ? 'top-8' : 'top-4'"
      >
        <span
          class="ml-auto font-normal leading-4 text-xxs"
          :class="hasUnread ? 'text-[#25D366]' : 'text-n-slate-10'"
        >
          <TimeAgo
            :last-activity-timestamp="chat.timestamp"
            :created-at-timestamp="chat.created_at"
          />
        </span>
        <span
          class="shadow-lg rounded-full text-xxs font-bold h-[18px] leading-[18px] ltr:ml-auto rtl:mr-auto mt-1 min-w-[18px] px-1.5 py-0 text-center text-white bg-[#25D366]"
          :class="hasUnread ? 'block' : 'hidden'"
        >
          {{ unreadCount > 9 ? '9+' : unreadCount }}
        </span>
      </div>
      <CardLabels
        v-if="showLabelsSection"
        :conversation-labels="chat.labels"
        class="mt-0.5 mx-2 mb-0"
      >
        <template v-if="hasSlaPolicyId" #before>
          <SLACardLabel :chat="chat" class="ltr:mr-1 rtl:ml-1" />
        </template>
      </CardLabels>
    </div>
    <ContextMenu
      v-if="showContextMenu"
      :x="contextMenu.x"
      :y="contextMenu.y"
      @close="closeContextMenu"
    >
      <ConversationContextMenu
        :status="chat.status"
        :inbox-id="inbox.id"
        :priority="chat.priority"
        :chat-id="chat.id"
        :has-unread-messages="hasUnread"
        :conversation-labels="chat.labels"
        :conversation-url="conversationPath"
        :allowed-options="allowedContextMenuOptions"
        @update-conversation="onUpdateConversation"
        @assign-agent="onAssignAgent"
        @assign-label="onAssignLabel"
        @remove-label="onRemoveLabel"
        @assign-team="onAssignTeam"
        @mark-as-unread="markAsUnread"
        @mark-as-read="markAsRead"
        @assign-priority="assignPriority"
        @delete-conversation="deleteConversation"
        @close="closeContextMenu"
      />
    </ContextMenu>
  </div>
</template>
