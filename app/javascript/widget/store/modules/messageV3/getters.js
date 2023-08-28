import Message from 'widget/store/modules/models/Message';

export const getters = {
  uIFlags: $state => $state.uiFlags,
  messageById: () => messageId => {
    const message = Message.find(messageId);
    return message;
  },
};
