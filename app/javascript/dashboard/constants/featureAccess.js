export const INTERNAL_CHAT_NOTIFICATION_TYPES = [
  'internal_chat_mention',
  'internal_chat_new_message',
];

// Store actions, with their payload, that drop what the client holds of a feature once the
// member loses access to it (`feature_access` on the account, `FeatureAccess` on the server).
export const FEATURE_ACCESS_RESETS = {
  'internal_chat.access': [
    ['internalChat/reset'],
    ['internalChatTypingStatus/reset'],
    ['notifications/removeOfTypes', INTERNAL_CHAT_NOTIFICATION_TYPES],
  ],
};
