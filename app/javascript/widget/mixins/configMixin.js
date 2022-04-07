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
    hasEndConversationEnabled() {
      return this.channelConfig.enabledFeatures.includes('end_conversation');
    },
    preChatFormEnabled() {
      return window.chatwootWebChannel.preChatFormEnabled;
    },
    preChatFormOptions() {
      let requireEmail = false;
      let preChatMessage = '';
      let preChatFields = null;
      const options = window.chatwootWebChannel.preChatFormOptions || {};
      requireEmail = options.require_email;
      preChatMessage = options.pre_chat_message;

      preChatFields =
        options.pre_chat_fields ||
        this.getDefaultPreChatFields({ requireEmail });
      return {
        requireEmail,
        preChatMessage,
        preChatFields,
      };
    },
    shouldShowPreChatForm() {
      const { preChatFields } = this.preChatFormOptions;
      // Check if at least one enabled filed in pre-chat fields
      const hasEnabledFields =
        preChatFields.filter(field => field.enabled).length > 0;
      return this.preChatFormEnabled && hasEnabledFields;
    },
  },
  methods: {
    getDefaultPreChatFields({ requireEmail }) {
      return [
        {
          label: 'Email Id',
          name: 'emailAddress',
          type: 'email',
          field_type: 'standard',
          required: requireEmail || false,
          enabled: requireEmail || false,
        },
        {
          label: 'Full name',
          name: 'fullName',
          type: 'text',
          field_type: 'standard',
          required: true,
          enabled: true,
        },
      ];
    },
  },
};
