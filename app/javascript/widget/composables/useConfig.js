import { computed } from 'vue';

/**
 * Composable for handling config-related computations.
 * @returns {Object} An object containing computed properties for various configuration settings.
 */
export function useConfig() {
  /**
   * Computed property to get the channel config.
   * @returns {Object} The channel configuration object.
   */
  const channelConfig = computed(() => window.chatwootWebChannel);

  const createFeatureChecker = feature =>
    computed(() => channelConfig.value.enabledFeatures.includes(feature));

  // Use the helper function for feature checks
  const useInboxAvatarForBot = createFeatureChecker('use_inbox_avatar_for_bot');
  const hasEmojiPickerEnabled = createFeatureChecker('emoji_picker');
  const hasAttachmentsEnabled = createFeatureChecker('attachments');
  const hasEndConversationEnabled = createFeatureChecker('end_conversation');

  /**
   * Computed property to check if the agent bot is connected.
   * @returns {Boolean} True if the agent bot is connected, false otherwise.
   */
  const hasAConnectedAgentBot = computed(
    () => !!channelConfig.value.hasAConnectedAgentBot
  );

  /**
   * Computed property to get the inbox avatar URL.
   * @returns {String} The inbox avatar URL.
   */
  const inboxAvatarUrl = computed(() => channelConfig.value.avatarUrl);

  /**
   * Computed property to check if the pre-chat form is enabled.
   * @returns {Boolean} True if the pre-chat form is enabled, false otherwise.
   */
  const preChatFormEnabled = computed(
    () => channelConfig.value.preChatFormEnabled
  );

  /**
   * Computed property to get the pre-chat form options.
   * @returns {Object} An object containing pre-chat message and fields.
   */
  const preChatFormOptions = computed(() => {
    const options = channelConfig.value.preChatFormOptions || {};
    const preChatMessage = options.pre_chat_message || '';
    const preChatFields = options.pre_chat_fields || [];
    return {
      preChatMessage,
      preChatFields,
    };
  });

  /**
   * Computed property to determine if the pre-chat form should be shown.
   * @returns {Boolean} True if the pre-chat form should be shown, false otherwise.
   */
  const shouldShowPreChatForm = computed(() => {
    if (!preChatFormEnabled.value) return false;
    const { preChatFields } = preChatFormOptions.value;
    return preChatFields.some(field => field.enabled);
  });

  return {
    useInboxAvatarForBot,
    hasAConnectedAgentBot,
    inboxAvatarUrl,
    channelConfig,
    hasEmojiPickerEnabled,
    hasAttachmentsEnabled,
    hasEndConversationEnabled,
    preChatFormEnabled,
    preChatFormOptions,
    shouldShowPreChatForm,
  };
}
