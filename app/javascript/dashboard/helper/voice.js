import { CONTENT_TYPES } from 'dashboard/components-next/message/constants';
import { useCallsStore } from 'dashboard/stores/calls';
import types from 'dashboard/store/mutation-types';

export const TERMINAL_STATUSES = [
  'completed',
  'busy',
  'failed',
  'no-answer',
  'canceled',
  'missed',
  'ended',
];

export const isInbound = direction => direction === 'inbound';

const isVoiceCallMessage = message => {
  return CONTENT_TYPES.VOICE_CALL === message?.content_type;
};

const shouldSkipCall = (callDirection, senderId, currentUserId) => {
  return callDirection === 'outbound' && senderId !== currentUserId;
};

const extractAssigneeId = conversation => {
  return conversation?.assignee_id || conversation?.meta?.assignee?.id || null;
};

const isAssignedToAnotherAgent = (assigneeId, currentUserId) => {
  if (currentUserId == null) return false;
  return !!assigneeId && assigneeId !== currentUserId;
};

const shouldShowCall = ({
  callDirection,
  senderId,
  assigneeId,
  currentUserId,
}) => {
  if (shouldSkipCall(callDirection, senderId, currentUserId)) return false;
  // Outbound calls are scoped to the initiator via shouldSkipCall; the
  // conversation may be auto-assigned to a different agent on creation, so
  // skip the assignee filter for outbound to avoid hiding the caller's own widget.
  if (callDirection === 'outbound') return true;
  return !isAssignedToAnotherAgent(assigneeId, currentUserId);
};

function extractCallData(message) {
  const call = message?.call || {};
  return {
    callSid: call.provider_call_id,
    status: call.status,
    callDirection: call.direction === 'outgoing' ? 'outbound' : 'inbound',
    conversationId: message?.conversation_id,
    assigneeId: extractAssigneeId(message?.conversation),
    senderId: message?.sender?.id,
  };
}

export function handleVoiceCallCreated(message, currentUserId) {
  if (!isVoiceCallMessage(message)) return;

  const { callSid, callDirection, conversationId, assigneeId, senderId } =
    extractCallData(message);

  if (
    !shouldShowCall({
      callDirection,
      senderId,
      assigneeId,
      currentUserId,
    })
  ) {
    return;
  }

  const callsStore = useCallsStore();
  callsStore.addCall({
    callSid,
    conversationId,
    callDirection,
    senderId,
  });
}

export function handleVoiceCallUpdated(commit, message, currentUserId) {
  if (!isVoiceCallMessage(message)) return;

  const {
    callSid,
    status,
    callDirection,
    conversationId,
    assigneeId,
    senderId,
  } = extractCallData(message);

  const callsStore = useCallsStore();

  callsStore.handleCallStatusChanged({ callSid, status, conversationId });

  commit(types.UPDATE_MESSAGE_CALL_STATUS, {
    conversationId,
    callStatus: status,
    callSid,
  });

  if (
    !shouldShowCall({
      callDirection,
      senderId,
      assigneeId,
      currentUserId,
    })
  ) {
    callsStore.removeCall(callSid);
    return;
  }

  if (status === 'ringing') {
    callsStore.addCall({
      callSid,
      conversationId,
      callDirection,
      senderId,
    });
  }
}

export function syncConversationCallVisibility(conversation, currentUserId) {
  const assigneeId = extractAssigneeId(conversation);
  if (!isAssignedToAnotherAgent(assigneeId, currentUserId)) return;

  const callsStore = useCallsStore();
  callsStore.removeCallsForConversation(conversation.id);
}
