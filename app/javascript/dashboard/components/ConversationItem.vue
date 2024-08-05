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
};
</script>

<template>
  <ConversationCard
    :key="source.id"
    :active-label="label"
    :team-id="teamId"
    :folders-id="foldersId"
    :chat="source"
    :conversation-type="conversationType"
    :selected="isConversationSelected(source.id)"
    :show-assignee="showAssignee"
    enable-context-menu
    @selectConversation="selectConversation"
    @deSelectConversation="deSelectConversation"
    @assignAgent="assignAgent"
    @assignTeam="assignTeam"
    @assignLabel="assignLabels"
    @updateConversationStatus="updateConversationStatus"
    @contextMenuToggle="toggleContextMenu"
    @markAsUnread="markAsUnread"
    @assignPriority="assignPriority"
  />
</template>
