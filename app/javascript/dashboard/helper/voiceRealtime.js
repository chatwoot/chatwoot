import { CONTENT_TYPES } from 'dashboard/components-next/message/constants';

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

const processVoiceCallData = (store, data, conversationId) => {
  const conv = store.state.conversations.allConversations.find(
    c => c?.id === Number(conversationId)
  );
  const inboxGetter = store.getters['inboxes/getInbox'];
  const inboxFromStore = inboxGetter?.(conv?.inbox_id || data?.inbox_id);

  return buildIncomingCallPayload(
    {
      ...data,
      conversation_id: conversationId,
      inbox_id: conv?.inbox_id || data?.inbox_id,
      account_id: conv?.account_id || data?.account_id,
      meta: conv?.meta || data?.meta,
    },
    inboxFromStore
  );
};

export const handleVoiceMessageUpdated = (app, data) => {
  if (!isVoiceCallMessage(data)) return;

  const store = app.$store;
  const status = data?.content_attributes?.data?.status;
  const callSid = data?.content_attributes?.data?.call_sid;
  const conversationId = data?.conversation_id;

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

  const hasIncoming = store.getters['calls/hasIncomingCall'];
  const hasActive = store.getters['calls/hasActiveCall'];

  if (status !== 'ringing' || hasIncoming || hasActive) return;

  const payload = processVoiceCallData(store, data, conversationId);

  if (payload.callSid) {
    store.dispatch('calls/setIncomingCall', payload);
  }
};

export const handleVoiceMessageCreated = (app, data) => {
  if (!isVoiceCallMessage(data)) return;

  const store = app.$store;
  const status = data?.content_attributes?.data?.status;
  const callSid = data?.content_attributes?.data?.call_sid;
  const conversationId = data?.conversation_id;

  if (!callSid) return;

  const payload = processVoiceCallData(store, data, conversationId);

  if (payload.callSid) {
    store.dispatch('calls/setIncomingCall', payload);
  }

  if (status) {
    store.dispatch('calls/handleCallStatusChanged', {
      callSid,
      status,
      conversationId,
    });
  }
};
