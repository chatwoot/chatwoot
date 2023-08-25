import Message from 'widget/models/Message';

export const getters = {
  uIFlags: $state => $state.uiFlags,
  messageById: () => messageId => {
    const message = Message.find(messageId);
    return message;
  },
};
