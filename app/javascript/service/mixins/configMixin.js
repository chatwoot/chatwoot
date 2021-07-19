export default {
  computed: {
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
      let requireEmail = false;
      let preChatMessage = '';
      const options = window.chatwootWebChannel.preChatFormOptions || {};
      if (!this.isOnNewConversation) {
        requireEmail = options.require_email;
        preChatMessage = options.pre_chat_message;
      }
      return {
        requireEmail,
        preChatMessage,
      };
    },
  },
};
