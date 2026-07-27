// A conversation's AI state is derived, not stored: pending + an active bot
// means the AI owns it; open means a human does; resolved means it has ended.
export const getAiState = (conversation, hasAiAgent) => {
  if (!conversation) return 'human';
  if (conversation.status === 'resolved') return 'resolved';
  if (conversation.status === 'pending' && hasAiAgent) return 'ai';
  return 'human';
};

export const isAiSection = conversation =>
  conversation?.widget_section === 'ai';
