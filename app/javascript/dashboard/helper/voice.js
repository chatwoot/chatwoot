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

function extractCallData(message) {
  const call = message?.call || {};
  return {
    callSid: call.provider_call_id,
    status: call.status,
    callDirection: call.direction === 'outgoing' ? 'outbound' : 'inbound',
    conversationId: message?.conversation_id,
    senderId: message?.sender?.id,
  };
}

export function handleVoiceCallCreated(message, currentUserId) {
  if (!isVoiceCallMessage(message)) return;

  const { callSid, callDirection, conversationId, senderId } =
    extractCallData(message);

  if (shouldSkipCall(callDirection, senderId, currentUserId)) return;

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

  const { callSid, status, callDirection, conversationId, senderId } =
    extractCallData(message);

  const callsStore = useCallsStore();

  callsStore.handleCallStatusChanged({ callSid, status, conversationId });

  commit(types.UPDATE_MESSAGE_CALL_STATUS, {
    conversationId,
    callStatus: status,
    callSid,
  });

  const isNewCall =
    status === 'ringing' &&
    !shouldSkipCall(callDirection, senderId, currentUserId);

  if (isNewCall) {
    callsStore.addCall({
      callSid,
      conversationId,
      callDirection,
      senderId,
    });
  }
}
