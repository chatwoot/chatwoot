<template>
  <conversation-card
    :key="source.id"
    :active-label="label"
    :team-id="teamId"
    :folders-id="foldersId"
    :chat="source"
    :conversation-type="conversationType"
    :status="status"
    :selected="isConversationSelected(source.id)"
    :show-assignee="showAssignee"
    :show-resolved-state="showResolvedState"
    :enable-context-menu="true"
    @select-conversation="selectConversation"
    @de-select-conversation="deSelectConversation"
    @assign-agent="assignAgent"
    @assign-team="assignTeam"
    @assign-label="assignLabels"
    @update-conversation-status="updateConversationStatus"
    @context-menu-toggle="toggleContextMenu"
    @mark-as-unread="markAsUnread"
    @assign-priority="assignPriority"
  />
</template>

<script>
import ConversationCard from './widgets/conversation/ConversationCard.vue';
import errorCaptureMixin from 'shared/mixins/errorCaptureMixin';
export default {
  components: {
    ConversationCard,
  },
  mixins: [errorCaptureMixin],
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
    status: {
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
    showResolvedState: {
      type: Boolean,
      default: false,
    },
  },
};
</script>
