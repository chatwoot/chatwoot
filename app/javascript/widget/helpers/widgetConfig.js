export const getChannelConfig = () => window.chatwootWebChannel;

export const useInboxAvatarForBot = () => {
  return getChannelConfig().enabledFeatures.includes(
    'use_inbox_avatar_for_bot'
  );
};

export const getInboxAvatarUrl = () => {
  return getChannelConfig().avatarUrl;
};

export const hasEmojiPickerEnabled = () => {
  return getChannelConfig().enabledFeatures.includes('emoji_picker');
};

export const hasAttachmentsEnabled = () => {
  return getChannelConfig().enabledFeatures.includes('attachments');
};

export const hasEndConversationEnabled = () => {
  return getChannelConfig().enabledFeatures.includes('end_conversation');
};

export const isPreChatFormEnabled = () => {
  return getChannelConfig().preChatFormEnabled;
};

export const getWebsiteName = () => {
  return getChannelConfig().websiteName;
};

export const workingHoursEnabled = () => {
  return getChannelConfig().workingHoursEnabled;
};

export const getPreChatFormOptions = () => {
  const options = getChannelConfig().preChatFormOptions || {};
  const preChatMessage = options.pre_chat_message || '';
  const { pre_chat_fields: preChatFields = [] } = options;
  return {
    preChatMessage,
    preChatFields,
  };
};

export const shouldShowPreChatForm = () => {
  const { preChatFields } = getPreChatFormOptions();
  const hasEnabledFields =
    preChatFields.filter(field => field.enabled).length > 0;
  return isPreChatFormEnabled() && hasEnabledFields;
};
