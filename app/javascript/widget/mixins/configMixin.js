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
    replyTime() {
      return window.chatwootWebChannel.replyTime;
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
    replyTimeStatus() {
      switch (this.replyTime) {
        case 'in_a_few_minutes':
          return this.$t('REPLY_TIME.IN_A_FEW_MINUTES');
        case 'in_a_few_hours':
          return this.$t('REPLY_TIME.IN_A_FEW_HOURS');
        case 'in_a_day':
          return this.$t('REPLY_TIME.IN_A_DAY');
        default:
          return this.$t('REPLY_TIME.IN_A_FEW_HOURS');
      }
    },
  },
};
