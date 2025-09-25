const isVoiceCallMessage = data =>
  data?.content_type === 12 || data?.content_type === 'voice_call';

const buildIncomingCallPayload = (data, inboxFromStore) => {
  const contentData = data.content_attributes?.data || {};
  return {
    callSid: contentData.call_sid,
    conversationId: data.display_id || data.id,
    inboxId: data.inbox_id || inboxFromStore?.id,
    inboxName: data.meta?.inbox?.name || inboxFromStore?.name,
    contactName: data.meta?.sender?.name || 'Unknown Caller',
    phoneNumber: data.meta?.sender?.phone_number,
    isOutbound: contentData.call_direction === 'outbound',
    callDirection: contentData.call_direction,
  };
};

export const handleVoiceMessageUpdated = (app, data) => {
  try {
    if (!isVoiceCallMessage(data)) {
      return;
    }

    const store = app.$store;
    const status = data?.content_attributes?.data?.status;
    const callSid = data?.content_attributes?.data?.call_sid;
    const conversationId = data?.conversation_id;

    if (!callSid || !status) {
      return;
    }

    store.dispatch('calls/handleCallStatusChanged', {
      callSid,
      status,
    });

    try {
      store.commit('UPDATE_CONVERSATION_CALL_STATUS', {
        conversationId,
        callStatus: status,
      });
    } catch (error) {
      // ignore commit errors
    }

    const hasIncoming = store.getters['calls/hasIncomingCall'];
    const hasActive = store.getters['calls/hasActiveCall'];

    if (status !== 'ringing' || hasIncoming || hasActive) {
      return;
    }

    const conversationGetter =
      store.getters['conversations/getConversationById'];
    const conv = conversationGetter?.(conversationId);
    const inboxGetter = store.getters['inboxes/getInbox'];
    const inboxFromStore = inboxGetter?.(conv?.inbox_id || data?.inbox_id);

    const payload = buildIncomingCallPayload(
      {
        ...data,
        display_id: conversationId,
        inbox_id: conv?.inbox_id || data?.inbox_id,
        account_id: conv?.account_id || data?.account_id,
        meta: conv?.meta || data?.meta,
      },
      inboxFromStore
    );

    if (payload.callSid) {
      store.dispatch('calls/setIncomingCall', payload);
    }
  } catch (error) {
    // ignore voice sync errors
  }
};

export const handleVoiceMessageCreated = (app, data) => {
  try {
    if (!isVoiceCallMessage(data)) {
      return;
    }

    const store = app.$store;
    const status = data?.content_attributes?.data?.status;
    const callSid = data?.content_attributes?.data?.call_sid;
    const conversationId = data?.conversation_id;

    if (!callSid) {
      return;
    }

    const conversationGetter =
      store.getters['conversations/getConversationById'];
    const conv = conversationGetter?.(conversationId);
    const inboxGetter = store.getters['inboxes/getInbox'];
    const inboxFromStore = inboxGetter?.(conv?.inbox_id || data?.inbox_id);

    const payload = buildIncomingCallPayload(
      {
        ...data,
        display_id: conversationId,
        inbox_id: conv?.inbox_id || data?.inbox_id,
        account_id: conv?.account_id || data?.account_id,
        meta: conv?.meta || data?.meta,
      },
      inboxFromStore
    );

    if (payload.callSid) {
      store.dispatch('calls/setIncomingCall', payload);
    }

    if (status) {
      store.dispatch('calls/handleCallStatusChanged', {
        callSid,
        status,
      });
    }
  } catch (error) {
    // ignore bootstrap errors
  }
};
