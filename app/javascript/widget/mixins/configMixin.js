export default {
  computed: {
    hideInputForBotConversations() {
      return window.chatwootWidgetDefaults.hideInputForBotConversations;
    },
    hideWelcomeHeader() {
      return window.chatwootWidgetDefaults.hideWelcomeHeader;
    },
    useInboxAvatarForBot() {
      return window.chatwootWidgetDefaults.useInboxAvatarForBot;
    },
    hasAConnectedAgentBot() {
      return !!window.chatwootWebChannel.hasAConnectedAgentBot;
    },
    inboxAvatarUrl() {
      return window.chatwootWebChannel.avatarUrl;
    },
    channelConfig() {
      return window.chatwootWebChannel;
    },
  },
};
