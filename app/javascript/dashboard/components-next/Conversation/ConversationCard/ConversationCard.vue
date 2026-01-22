<script setup>
import { computed, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useBreakpoints } from '@vueuse/core';
import { useMapGetter } from 'dashboard/composables/store';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import wootConstants from 'dashboard/constants/globals';
import ContextMenu from 'dashboard/components/ui/ContextMenu.vue';
import ConversationContextMenu from 'dashboard/components/widgets/conversation/contextMenu/Index.vue';
import ConversationCardExpanded from './ConversationCardExpanded.vue';
import ConversationCardCompact from './ConversationCardCompact.vue';

const props = defineProps({
  activeLabel: { type: String, default: '' },
  chat: { type: Object, default: () => ({}) },
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
  isExpandedLayout: { type: Boolean, default: false },
  isPreviousConversations: { type: Boolean, default: false },
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

const breakpoints = useBreakpoints({
  lg: wootConstants.LARGE_SCREEN_BREAKPOINT,
});
const isLargeScreen = breakpoints.greaterOrEqual('lg');

// Show expanded only when: isExpandedLayout=true AND screen >= 1024px
const showExpanded = computed(() => {
  return props.isExpandedLayout && isLargeScreen.value;
});

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
const currentContact = computed(() =>
  senderId.value ? contactGetter.value(senderId.value) : {}
);
const hasActiveInbox = computed(() => activeInbox.value);

const isActiveChat = computed(() => currentChat.value.id === props.chat.id);
const inbox = computed(() => {
  const inboxId = props.chat.inbox_id;
  return inboxId ? inboxGetter.value(inboxId) : {};
});

const showInboxName = computed(() => inboxesList.value.length > 1);

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
  <!-- Expanded: Only when isExpandedLayout=true AND screen >= 1024px -->
  <ConversationCardExpanded
    v-if="showExpanded"
    :chat="chat"
    :current-contact="currentContact"
    :assignee="assignee"
    :inbox="inbox"
    :selected="selected"
    :is-active-chat="isActiveChat"
    :show-assignee="showAssignee"
    :show-inbox-name="showInboxName"
    :is-inbox-view="hasActiveInbox && !isPreviousConversations"
    @select-conversation="onSelectConversation"
    @de-select-conversation="onSelectConversation"
    @click="onCardClick"
    @contextmenu="openContextMenu"
  />

  <!-- Compact: All other cases (mobile OR isExpandedLayout=false) -->
  <ConversationCardCompact
    v-else
    :chat="chat"
    :current-contact="currentContact"
    :assignee="assignee"
    :inbox="inbox"
    :selected="selected"
    :is-active-chat="isActiveChat"
    :compact="compact"
    :show-assignee="showAssignee"
    :show-inbox-name="showInboxName"
    :hide-thumbnail="hideThumbnail"
    :enable-selection="enableSelection"
    :is-inbox-view="hasActiveInbox && !isPreviousConversations"
    @select-conversation="onSelectConversation"
    @click="onCardClick"
    @contextmenu="openContextMenu"
  />

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
      :has-unread-messages="chat.unread_count > 0"
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
</template>
