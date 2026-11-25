// `labelKey` is resolved under INTERNAL_CHAT.REACTIONS by the components that
// render these, since the label surfaces as a tooltip and an accessible label.
export const QUICK_EMOJIS = [
  { emoji: '👍', labelKey: 'THUMBS_UP' },
  { emoji: '❤️', labelKey: 'HEART' },
  { emoji: '😂', labelKey: 'JOY' },
  { emoji: '😮', labelKey: 'SURPRISED' },
  { emoji: '😢', labelKey: 'SAD' },
  { emoji: '🙏', labelKey: 'PRAY' },
  { emoji: '🔥', labelKey: 'FIRE' },
  { emoji: '🎉', labelKey: 'PARTY' },
];

export const findOwnReaction = (reactions, emoji, userId) =>
  reactions.find(r => r.emoji === emoji && r.user_id === userId) || null;
