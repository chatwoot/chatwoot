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
  return !!assigneeId && assigneeId !== currentUserId;
};

const shouldShowCall = ({
  callDirection,
  senderId,
  assigneeId,
  currentUserId,
}) => {
  return (
    !shouldSkipCall(callDirection, senderId, currentUserId) &&
    !isAssignedToAnotherAgent(assigneeId, currentUserId)
  );
};

function extractCallData(message) {
  const contentData = message?.content_attributes?.data || {};
  return {
    callSid: contentData.call_sid,
    status: contentData.status,
    callDirection: contentData.call_direction,
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

  const callInfo = { conversationId, callStatus: status };
  commit(types.UPDATE_CONVERSATION_CALL_STATUS, callInfo);
  commit(types.UPDATE_MESSAGE_CALL_STATUS, callInfo);

  if (
    !shouldShowCall({
      callDirection,
      senderId,
      assigneeId,
      currentUserId,
    })
  ) {
    callsStore.removeCallsForConversation(conversationId);
    return;
  }

  const isNewCall = status === 'ringing';

  if (isNewCall) {
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
