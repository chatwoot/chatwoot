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

const isWhatsappCall = message => {
  return message?.content_attributes?.data?.call_source === 'whatsapp';
};

const shouldSkipCall = (callDirection, senderId, currentUserId) => {
  return callDirection === 'outbound' && senderId !== currentUserId;
};

function extractCallData(message) {
  const contentData = message?.content_attributes?.data || {};
  return {
    callSid: contentData.call_sid,
    status: contentData.status,
    callDirection: contentData.call_direction,
    conversationId: message?.conversation_id,
    senderId: message?.sender?.id,
  };
}

export function handleVoiceCallCreated(message, currentUserId) {
  if (!isVoiceCallMessage(message)) return;

  // WhatsApp calls are managed by their own store (whatsappCalls),
  // don't add them to the Twilio calls store.
  if (isWhatsappCall(message)) return;

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

  // Vuex message/conversation status updates apply to all call sources
  const callInfo = { conversationId, callStatus: status };
  commit(types.UPDATE_CONVERSATION_CALL_STATUS, callInfo);
  commit(types.UPDATE_MESSAGE_CALL_STATUS, callInfo);

  // Twilio-specific store interactions — skip for WhatsApp calls
  if (isWhatsappCall(message)) return;

  const callsStore = useCallsStore();

  callsStore.handleCallStatusChanged({ callSid, status, conversationId });

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
