<script setup>
import { inject } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert, useTrack } from 'dashboard/composables';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useBulkActions } from 'dashboard/composables/chatlist/useBulkActions';
import { useConversationRequiredAttributes } from 'dashboard/composables/useConversationRequiredAttributes';
import ConversationCard from 'dashboard/components-next/Conversation/ConversationCard/ConversationCardV5.vue';
import wootConstants from 'dashboard/constants/globals';

const props = defineProps({
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
  showAssignee: {
    type: Boolean,
    default: false,
  },
  isExpandedLayout: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'deleteConversation',
  'showResolveAttributesModal',
  'redirectToList',
]);

const store = useStore();
const { t } = useI18n();

const selectConversation = inject('selectConversation');
const deSelectConversation = inject('deSelectConversation');
const toggleContextMenu = inject('toggleContextMenu');
const isConversationSelected = inject('isConversationSelected');

const { checkMissingAttributes } = useConversationRequiredAttributes();

const { onAssignAgent, onAssignLabels, onRemoveLabels } = useBulkActions();

async function assignTeam(team, conversationId = null) {
  try {
    await store.dispatch('assignTeam', {
      conversationId,
      teamId: team.id,
    });
    useAlert(
      t('CONVERSATION.CARD_CONTEXT_MENU.API.TEAM_ASSIGNMENT.SUCCESFUL', {
        team: team.name,
        conversationId,
      })
    );
  } catch (error) {
    useAlert(t('CONVERSATION.CARD_CONTEXT_MENU.API.TEAM_ASSIGNMENT.FAILED'));
  }
}

function toggleConversationStatus(
  conversationId,
  status,
  snoozedUntil,
  customAttributes = null
) {
  const payload = {
    conversationId,
    status,
    snoozedUntil,
  };

  if (customAttributes) {
    payload.customAttributes = customAttributes;
  }

  store.dispatch('toggleStatus', payload).then(() => {
    useAlert(t('CONVERSATION.CHANGE_STATUS'));
  });
}

function updateConversationStatus(conversationId, status, snoozedUntil) {
  if (status !== wootConstants.STATUS_TYPE.RESOLVED) {
    toggleConversationStatus(conversationId, status, snoozedUntil);
    return;
  }

  // Check for required attributes before resolving
  const conversation = store.getters.getConversationById(conversationId);
  const currentCustomAttributes = conversation?.custom_attributes || {};
  const { hasMissing, missing } = checkMissingAttributes(
    currentCustomAttributes
  );

  if (hasMissing) {
    // Emit event to parent to show modal
    emit('showResolveAttributesModal', {
      conversationId,
      snoozedUntil,
      missing,
      currentCustomAttributes,
    });
  } else {
    toggleConversationStatus(conversationId, status, snoozedUntil);
  }
}

async function assignPriority(priority, conversationId = null) {
  store.dispatch('setCurrentChatPriority', {
    priority,
    conversationId,
  });
  store.dispatch('assignPriority', { conversationId, priority }).then(() => {
    useTrack(CONVERSATION_EVENTS.CHANGE_PRIORITY, {
      newValue: priority,
      from: 'Context menu',
    });
    useAlert(
      t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.SUCCESSFUL', {
        priority,
        conversationId,
      })
    );
  });
}

async function markAsUnread(conversationId) {
  try {
    emit('redirectToList');
    await store.dispatch('markMessagesUnread', {
      id: conversationId,
    });
  } catch (error) {
    // Ignore error
  }
}

async function markAsRead(conversationId) {
  try {
    await store.dispatch('markMessagesRead', {
      id: conversationId,
    });
  } catch (error) {
    // Ignore error
  }
}

function handleDelete() {
  emit('deleteConversation', props.source.id);
}
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
    :is-expanded-layout="isExpandedLayout"
    enable-context-menu
    @select-conversation="selectConversation"
    @de-select-conversation="deSelectConversation"
    @assign-agent="onAssignAgent"
    @assign-team="assignTeam"
    @assign-label="onAssignLabels"
    @remove-label="onRemoveLabels"
    @update-conversation-status="updateConversationStatus"
    @context-menu-toggle="toggleContextMenu"
    @mark-as-unread="markAsUnread"
    @mark-as-read="markAsRead"
    @assign-priority="assignPriority"
    @delete-conversation="handleDelete"
  />
</template>
