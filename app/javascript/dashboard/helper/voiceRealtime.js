import { CONTENT_TYPES } from 'dashboard/components-next/message/constants';

// Magic number 12 should be replaced with proper constant
const VOICE_CALL_LEGACY_TYPE = 12;
const VOICE_CALL_TYPES = [CONTENT_TYPES.VOICE_CALL, VOICE_CALL_LEGACY_TYPE];

const isVoiceCallMessage = data =>
  VOICE_CALL_TYPES.includes(data?.content_type);

const buildIncomingCallPayload = (data, inboxFromStore) => {
  const contentData = data.content_attributes?.data || {};
  return {
    callSid: contentData.call_sid,
    conversationId: data.conversation_id,
    inboxId: data.inbox_id,
    inboxName: data.meta?.inbox?.name || inboxFromStore?.name,
    contactName: data.meta?.sender?.name || 'Unknown caller',
    phoneNumber: data.meta?.sender?.phone_number,
    isOutbound: contentData.call_direction === 'outbound',
    callDirection: contentData.call_direction,
  };
};

const getConversationAndInbox = (store, conversationId, fallbackInboxId) => {
  const conv = store.state.conversations.allConversations.find(
    c => c?.id === Number(conversationId)
  );
  const inboxGetter = store.getters['inboxes/getInbox'];
  const inboxFromStore = inboxGetter?.(conv?.inbox_id || fallbackInboxId);
  return { conv, inboxFromStore };
};

const buildPayloadData = (data, conv, conversationId) => ({
  ...data,
  conversation_id: conversationId,
  inbox_id: conv?.inbox_id || data?.inbox_id,
  account_id: conv?.account_id || data?.account_id,
  meta: conv?.meta || data?.meta,
});

const handleCallStatus = (store, { callSid, status, conversationId }) => {
  if (!callSid || !status) return;

  store.dispatch('calls/handleCallStatusChanged', {
    callSid,
    status,
    conversationId,
  });
  store.commit('UPDATE_CONVERSATION_CALL_STATUS', {
    conversationId,
    callStatus: status,
  });
};

const setIncomingCallIfValid = (store, payload) => {
  if (payload.callSid) {
    store.dispatch('calls/setIncomingCall', payload);
  }
};

export const handleVoiceMessageUpdated = (app, data) => {
  if (!isVoiceCallMessage(data)) return;

  const store = app.$store;
  const { status, call_sid: callSid } = data?.content_attributes?.data || {};
  const conversationId = data?.conversation_id;

  if (!callSid || !status) return;

  handleCallStatus(store, { callSid, status, conversationId });

  const hasIncoming = store.getters['calls/hasIncomingCall'];
  const hasActive = store.getters['calls/hasActiveCall'];

  if (status !== 'ringing' || hasIncoming || hasActive) return;

  const { conv, inboxFromStore } = getConversationAndInbox(
    store,
    conversationId,
    data?.inbox_id
  );
  const payloadData = buildPayloadData(data, conv, conversationId);
  const payload = buildIncomingCallPayload(payloadData, inboxFromStore);

  setIncomingCallIfValid(store, payload);
};

export const handleVoiceMessageCreated = (app, data) => {
  if (!isVoiceCallMessage(data)) return;

  const store = app.$store;
  const { status, call_sid: callSid } = data?.content_attributes?.data || {};
  const conversationId = data?.conversation_id;

  if (!callSid) return;

  const { conv, inboxFromStore } = getConversationAndInbox(
    store,
    conversationId,
    data?.inbox_id
  );
  const payloadData = buildPayloadData(data, conv, conversationId);
  const payload = buildIncomingCallPayload(payloadData, inboxFromStore);

  setIncomingCallIfValid(store, payload);

  if (status) {
    handleCallStatus(store, { callSid, status, conversationId });
  }
};
