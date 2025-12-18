import { CONTENT_TYPES } from 'dashboard/components-next/message/constants';
import { useCallsStore } from 'dashboard/stores/calls';
import types from 'dashboard/store/mutation-types';

const isVoiceCallMessage = message => {
  return CONTENT_TYPES.VOICE_CALL === message?.content_type;
};

function extractCallData(message) {
  const contentData = message?.content_attributes?.data || {};
  return {
    callSid: contentData.call_sid,
    status: contentData.status,
    callDirection: contentData.call_direction,
    conversationId: message?.conversation_id,
  };
}

export function handleVoiceCallCreated(message) {
  if (!isVoiceCallMessage(message)) return;

  const { callSid, callDirection, conversationId } = extractCallData(message);
  const callsStore = useCallsStore();
  callsStore.setIncomingCall({ callSid, conversationId, callDirection });
}

export function handleVoiceCallUpdated(commit, message) {
  if (!isVoiceCallMessage(message)) return;

  const { callSid, status, callDirection, conversationId } =
    extractCallData(message);

  const callsStore = useCallsStore();

  callsStore.handleCallStatusChanged({ callSid, status, conversationId });

  const callInfo = { conversationId, callStatus: status };
  commit(types.UPDATE_CONVERSATION_CALL_STATUS, callInfo);
  commit(types.UPDATE_MESSAGE_CALL_STATUS, callInfo);

  const isNewIncomingCall =
    status === 'ringing' &&
    !callsStore.hasIncomingCall &&
    !callsStore.hasActiveCall;

  if (isNewIncomingCall) {
    callsStore.setIncomingCall({ callSid, conversationId, callDirection });
  }
}
