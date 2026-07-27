import { defineStore } from 'pinia';
import { ref } from 'vue';
import {
  fetchMessages,
  createMessage,
  createAttachmentMessage,
  updateMessage,
} from 'widget-v2/api/messages';

const MESSAGE_TYPE = { INCOMING: 0, OUTGOING: 1, ACTIVITY: 2, TEMPLATE: 3 };

const emptyThread = () => ({ messages: [], allFetched: false, loading: false });

export const useMessagesStore = defineStore('messages', () => {
  const threads = ref({});

  const thread = displayId => {
    if (!threads.value[displayId]) {
      threads.value = { ...threads.value, [displayId]: emptyThread() };
    }
    return threads.value[displayId];
  };

  const upsertMessage = (displayId, message) => {
    const current = thread(displayId);
    // A message can arrive twice: as the API echo of a send and again over the
    // cable. Match by id first, then by echo_id for optimistic entries.
    const index = current.messages.findIndex(
      existing =>
        existing.id === message.id ||
        (message.echo_id && existing.id === message.echo_id)
    );
    if (index >= 0) {
      current.messages.splice(index, 1, {
        ...current.messages[index],
        ...message,
        status: 'sent',
      });
    } else {
      current.messages.push(message);
      current.messages.sort((a, b) => a.created_at - b.created_at);
    }
  };

  const load = async (displayId, { before } = {}) => {
    const current = thread(displayId);
    if (current.loading) return;
    current.loading = true;
    try {
      const { payload } = await fetchMessages(displayId, { before });
      if (!payload.length) current.allFetched = true;
      payload.forEach(message => upsertMessage(displayId, message));
    } finally {
      current.loading = false;
    }
  };

  const send = async (displayId, content) => {
    const echoId = `echo-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    upsertMessage(displayId, {
      id: echoId,
      content,
      message_type: MESSAGE_TYPE.INCOMING,
      content_type: 'text',
      created_at: Math.floor(Date.now() / 1000),
      status: 'sending',
    });
    try {
      const message = await createMessage(displayId, { content, echoId });
      upsertMessage(displayId, { ...message, echo_id: echoId });
    } catch (error) {
      const current = thread(displayId);
      const pending = current.messages.find(message => message.id === echoId);
      if (pending) pending.status = 'failed';
      throw error;
    }
  };

  const sendAttachment = async (displayId, attachment) => {
    const echoId = `echo-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const message = await createAttachmentMessage(displayId, {
      attachment,
      echoId,
    });
    upsertMessage(displayId, { ...message, echo_id: echoId });
  };

  const update = async (displayId, messageId, payload) => {
    const message = await updateMessage(displayId, messageId, payload);
    upsertMessage(displayId, message);
  };

  return { threads, thread, upsertMessage, load, send, sendAttachment, update };
});
