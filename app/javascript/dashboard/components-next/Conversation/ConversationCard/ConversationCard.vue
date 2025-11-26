<script setup>
import { computed, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import ContextMenu from 'dashboard/components/ui/ContextMenu.vue';
import ConversationContextMenu from 'dashboard/components/widgets/conversation/contextMenu/Index.vue';
import CardMetaSection from './CardMetaSection.vue';
import CardAvatar from './CardAvatar.vue';
import CardHeader from './CardHeader.vue';
import CardContent from './CardContent.vue';
import CardLabels from './CardLabels.vue';

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
  enableSelection: { type: Boolean, default: true },
});

const emit = defineEmits([
  'contextMenuToggle',
  'assignAgent',
  'assignLabel',
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

const showContextMenu = ref(false);
const contextMenu = ref({ x: null, y: null });

const currentChat = useMapGetter('getSelectedChat');
const inboxesList = useMapGetter('inboxes/getInboxes');
const activeInbox = useMapGetter('getSelectedInbox');
const accountId = useMapGetter('getCurrentAccountId');
const contactGetter = useMapGetter('contacts/getContact');
const inboxGetter = useMapGetter('inboxes/getInbox');

const chatMetadata = computed(() => props.chat.meta || {});
const assignee = computed(() => chatMetadata.value.assignee || {});
const senderId = computed(() => chatMetadata.value.sender?.id);

const currentContact = computed(() => {
  return senderId.value ? contactGetter.value(senderId.value) : {};
});

const isActiveChat = computed(() => currentChat.value.id === props.chat.id);
const unreadCount = computed(() => props.chat.unread_count);
const isInboxNameVisible = computed(() => !activeInbox.value);
const lastMessageInChat = computed(() => getLastMessage(props.chat));

const voiceCallData = computed(() => ({
  status: props.chat.additional_attributes?.call_status,
  direction: props.chat.additional_attributes?.call_direction,
}));

const inboxId = computed(() => props.chat.inbox_id);

const inbox = computed(() =>
  inboxId.value ? inboxGetter.value(inboxId.value) : {}
);

const showInboxName = computed(() => {
  return (
    !props.hideInboxName &&
    isInboxNameVisible.value &&
    inboxesList.value.length > 1
  );
});

const showLabelsSection = computed(() => props.chat.labels?.length > 0);

const showExpandedPreview = computed(() => {
  return props.compact && !showLabelsSection.value;
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

  if (e.metaKey || e.ctrlKey) {
    e.preventDefault();
    window.open(
      `${window.chatwootConfig.hostURL}${path}`,
      '_blank',
      'noopener,noreferrer'
    );
    return;
  }

  if (isActiveChat.value) return;
  router.push({ path });
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
  closeContextMenu();
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
    class="relative flex items-start flex-grow-0 flex-shrink-0 w-auto max-w-full cursor-pointer group transition-all duration-200"
    :class="{
      'active animate-card-select bg-n-alpha-1 dark:bg-n-alpha-3': isActiveChat,
      'bg-n-slate-2 dark:bg-n-slate-3': selected,
      'px-0 py-3': compact,
      'px-2 pt-2.5 pb-3 hover:bg-n-alpha-1 rounded-lg': !compact,
    }"
    @click="onCardClick"
    @contextmenu="openContextMenu($event)"
  >
    <div class="min-w-0 w-full">
      <CardMetaSection
        :chat="chat"
        :inbox="inbox"
        :show-inbox-name="showInboxName"
        :show-assignee="showAssignee"
        :assignee="assignee"
      />

      <div
        class="grid gap-2.5 items-start"
        :class="{
          'mt-0.5 grid-cols-1': compact,
          'grid-cols-[auto,1fr]': !compact,
        }"
      >
        <CardAvatar
          v-if="!compact"
          :contact="currentContact"
          :selected="selected"
          :enable-selection="enableSelection"
          :hide-thumbnail="hideThumbnail"
          @select-conversation="onSelectConversation"
        />

        <div class="min-w-0 flex flex-col gap-1">
          <div class="min-w-0 flex flex-col gap-px">
            <CardHeader
              v-if="!compact"
              :contact-name="currentContact.name"
              :timestamp="chat.timestamp"
              :created-at="chat.created_at"
            />

            <CardContent
              :last-message="lastMessageInChat"
              :voice-call-status="voiceCallData.status"
              :voice-call-direction="voiceCallData.direction"
              :unread-count="unreadCount"
              :show-expanded-preview="showExpandedPreview"
            />
          </div>

          <CardLabels
            v-if="showLabelsSection"
            :conversation-labels="chat.labels"
            class="mt-0.5 mb-0"
          />
        </div>
      </div>
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
        :has-unread-messages="unreadCount > 0"
        :conversation-url="conversationPath"
        :allowed-options="allowedContextMenuOptions"
        @update-conversation="onUpdateConversation"
        @assign-agent="onAssignAgent"
        @assign-label="onAssignLabel"
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
