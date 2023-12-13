<template>
  <conversation-card
    :key="source.id"
    :active-label="label"
    :team-id="teamId"
    :folders-id="foldersId"
    :chat="source"
    :conversation-type="conversationType"
    :selected="isConversationSelected(source.id)"
    :show-assignee="showAssignee"
    :enable-context-menu="true"
    @select-conversation="onSelectConversation"
    @de-select-conversation="onDeSelectConversation"
    @assign-agent="onAssignAgent"
    @assign-team="onAssignTeam"
    @assign-label="onAssignLabel"
    @update-conversation-status="toggleConversationStatus"
    @context-menu-toggle="onContextMenuToggle"
    @mark-as-unread="onClickMarkAsUnread"
    @assign-priority="onAssignPriority"
  />
</template>

<script>
import ConversationCard from './widgets/conversation/ConversationCard.vue';
export default {
  components: {
    ConversationCard,
  },
  inject: [
    'selectConversation',
    'deSelectConversation',
    'assignAgent',
    'assignTeam',
    'assignLabels',
    'updateConversationStatus',
    'toggleContextMenu',
    'markAsUnread',
    'assignPriority',
  ],
  props: {
    source: {
      type: Object,
      required: true,
    },
    teamId: {
      type: [String, Number],
      default: 0,
    },
    label: {
      type: String,
      default: '',
    },
    conversationType: {
      type: String,
      default: '',
    },
    foldersId: {
      type: [String, Number],
      default: 0,
    },
    isConversationSelected: {
      type: Function,
      default: () => {},
    },
    showAssignee: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    onSelectConversation(conversationId, inboxId) {
      this.selectConversation(conversationId, inboxId);
    },
    onDeSelectConversation(conversationId, inboxId) {
      this.deSelectConversation(conversationId, inboxId);
    },
    onAssignAgent(agent, conversationId) {
      this.assignAgent(agent, conversationId);
    },
    onAssignTeam(team, conversationId) {
      this.assignTeam(team, conversationId);
    },
    onAssignLabel(labelTitle, conversationId) {
      this.assignLabels(labelTitle, conversationId);
    },
    toggleConversationStatus(conversationId, status, snoozedUntil) {
      this.updateConversationStatus(conversationId, status, snoozedUntil);
    },
    onContextMenuToggle(value) {
      this.toggleContextMenu(value);
    },
    onClickMarkAsUnread(conversationId) {
      this.markAsUnread(conversationId);
    },
    onAssignPriority(priority, conversationId) {
      this.assignPriority(priority, conversationId);
    },
  },
};
</script>
