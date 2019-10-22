/* eslint no-console: 0 */
/* eslint no-param-reassign: 0 */
export default Vuex => {
  const wootState = new Vuex.Store({
    state: {
      authenticated: false,
      currentChat: null,
    },
    mutations: {
      // Authentication mutations
      authenticate(state) {
        state.authenticated = true;
      },
      logout(state) {
        state.authenticated = false;
      },

      // CurrentChat Mutations
      setCurrentChat(state, chat) {
        state.currentChat = chat;
      },
    },
    getters: {
      currentChat(state) {
        return state.currentChat;
      },
    },
  });
  return wootState;
};
