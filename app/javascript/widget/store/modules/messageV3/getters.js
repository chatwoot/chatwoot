export const getters = {
  uIFlags: $state => $state.uiFlags,
  messageById: _state => messageId => {
    const message = _state.messages.byId[messageId];
    return message;
  },
};
