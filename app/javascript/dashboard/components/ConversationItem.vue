<script setup>
import { inject, ref } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert, useTrack } from 'dashboard/composables';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useBulkActions } from 'dashboard/composables/chatlist/useBulkActions';
import ConversationCard from 'dashboard/components-next/Conversation/ConversationCard/ConversationCard.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

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

const store = useStore();
const router = useRouter();
const { t } = useI18n();

const selectConversation = inject('selectConversation');
const deSelectConversation = inject('deSelectConversation');
const toggleContextMenu = inject('toggleContextMenu');
const isConversationSelected = inject('isConversationSelected');

const deleteConversationDialogRef = ref(null);

const { onAssignAgent, onAssignLabels } = useBulkActions();

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

function updateConversationStatus(conversationId, status, snoozedUntil) {
  store
    .dispatch('toggleStatus', {
      conversationId,
      status,
      snoozedUntil,
    })
    .then(() => {
      useAlert(t('CONVERSATION.CHANGE_STATUS'));
    });
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

function redirectToConversationList() {
  const accountId = store.getters.getCurrentAccountId;
  const conversationType = props.conversationType || '';
  const inboxId = store.getters.getSelectedInbox?.id;

  let path = `/app/accounts/${accountId}/conversations`;

  if (conversationType === 'mention') {
    path = `/app/accounts/${accountId}/mentions/conversations`;
  } else if (conversationType === 'unattended') {
    path = `/app/accounts/${accountId}/unattended/conversations`;
  } else if (props.foldersId) {
    path = `/app/accounts/${accountId}/custom_view/${props.foldersId}`;
  } else if (inboxId) {
    path = `/app/accounts/${accountId}/inbox/${inboxId}`;
  } else if (props.teamId) {
    path = `/app/accounts/${accountId}/team/${props.teamId}`;
  } else if (props.label) {
    path = `/app/accounts/${accountId}/label/${props.label}`;
  }

  router.push(path);
}

async function markAsUnread(conversationId) {
  try {
    await store.dispatch('markMessagesUnread', {
      id: conversationId,
    });
    redirectToConversationList();
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
  deleteConversationDialogRef.value.open();
}

async function deleteConversation() {
  try {
    await store.dispatch('deleteConversation', props.source.id);
    redirectToConversationList();
    deleteConversationDialogRef.value.close();
    useAlert(t('CONVERSATION.SUCCESS_DELETE_CONVERSATION'));
  } catch (error) {
    useAlert(t('CONVERSATION.FAIL_DELETE_CONVERSATION'));
  }
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
    @update-conversation-status="updateConversationStatus"
    @context-menu-toggle="toggleContextMenu"
    @mark-as-unread="markAsUnread"
    @mark-as-read="markAsRead"
    @assign-priority="assignPriority"
    @delete-conversation="handleDelete"
  />

  <Dialog
    ref="deleteConversationDialogRef"
    type="alert"
    :title="
      $t('CONVERSATION.DELETE_CONVERSATION.TITLE', {
        conversationId: source.id,
      })
    "
    :description="$t('CONVERSATION.DELETE_CONVERSATION.DESCRIPTION')"
    :confirm-button-label="$t('CONVERSATION.DELETE_CONVERSATION.CONFIRM')"
    @confirm="deleteConversation"
  />
</template>
