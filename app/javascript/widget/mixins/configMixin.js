export default {
  computed: {
    hideInputForBotConversations() {
      return window.chatwootWebChannel.hideInputForBotConversations;
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
    hasEmojiPickerEnabled() {
      return this.channelConfig.enabledFeatures.includes('emoji_picker');
    },
    hasAttachmentsEnabled() {
      return this.channelConfig.enabledFeatures.includes('attachments');
    },
    preChatFormEnabled() {
      return window.chatwootWebChannel.preChatFormEnabled;
    },
    preChatFormOptions() {
      const options = window.chatwootWebChannel.preChatFormOptions || {};
      return {
        requireEmail: options.require_email,
        preChatMessage: options.pre_chat_message,
      };
    },
  },
};
