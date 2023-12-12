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
    @select-conversation="selectConversation"
    @de-select-conversation="deSelectConversation"
    @assign-agent="onAssignAgent"
    @assign-team="onAssignTeam"
    @assign-label="onAssignLabel"
    @update-conversation-status="toggleConversationStatus"
    @context-menu-toggle="onContextMenuToggle"
    @mark-as-unread="markAsUnread"
    @assign-priority="assignPriority"
  />
</template>

<script>
import ConversationCard from './widgets/conversation/ConversationCard.vue';
export default {
  components: {
    ConversationCard,
  },
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
    selectConversation(conversationId, inboxId) {
      this.$parent.$parent.$emit(
        'select-conversation',
        conversationId,
        inboxId
      );
    },
    deSelectConversation(conversationId, inboxId) {
      this.$parent.$parent.$emit(
        'de-select-conversation',
        conversationId,
        inboxId
      );
    },
    onAssignAgent(agent, conversationId) {
      this.$parent.$parent.$emit('assign-agent', agent, conversationId);
    },
    onAssignTeam(team, conversationId) {
      this.$parent.$parent.$emit('assign-team', team, conversationId);
    },
    onAssignLabel(labelTitle, conversationId) {
      this.$parent.$parent.$emit('assign-label', labelTitle, conversationId);
    },
    toggleConversationStatus(conversationId, status, snoozedUntil) {
      this.$parent.$parent.$emit(
        'update-conversation-status',
        conversationId,
        status,
        snoozedUntil
      );
    },
    onContextMenuToggle(value) {
      this.$parent.$parent.$emit('context-menu-toggle', value);
    },
    markAsUnread(conversationId) {
      this.$parent.$parent.$emit('mark-as-unread', conversationId);
    },
    assignPriority(priority, conversationId) {
      this.$parent.$parent.$emit('assign-priority', priority, conversationId);
    },
  },
};
</script>
