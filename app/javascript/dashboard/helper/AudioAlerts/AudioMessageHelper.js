export const getAssignee = conversationEvent => {
  const messageAssigneeId = conversationEvent?.conversation?.assignee_id;
  if (messageAssigneeId !== undefined) return messageAssigneeId;

  return conversationEvent?.meta?.assignee_type === 'User'
    ? conversationEvent.meta.assignee?.id
    : undefined;
};
export const isConversationUnassigned = conversationEvent =>
  !getAssignee(conversationEvent);
export const isConversationAssignedToMe = (conversationEvent, currentUserId) =>
  getAssignee(conversationEvent) === currentUserId;
export const isMessageFromCurrentUser = (message, currentUserId) =>
  message?.sender?.id === currentUserId;
