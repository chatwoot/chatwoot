import {
  getAssignee,
  isConversationUnassigned,
  isConversationAssignedToMe,
  isMessageFromCurrentUser,
} from '../AudioMessageHelper';

describe('getAssignee', () => {
  it('should return assignee_id when present', () => {
    const message = { conversation: { assignee_id: 1 } };
    expect(getAssignee(message)).toBe(1);
  });

  it('should return undefined when no assignee_id', () => {
    const message = { conversation: null };
    expect(getAssignee(message)).toBeUndefined();
  });

  it('should handle null message', () => {
    expect(getAssignee(null)).toBeUndefined();
  });
});

describe('isConversationUnassigned', () => {
  it('should return true when no assignee', () => {
    const message = { conversation: { assignee_id: null } };
    expect(isConversationUnassigned(message)).toBe(true);
  });

  it('should return false when has assignee', () => {
    const message = { conversation: { assignee_id: 1 } };
    expect(isConversationUnassigned(message)).toBe(false);
  });

  it('should handle null message', () => {
    expect(isConversationUnassigned(null)).toBe(true);
  });
});

describe('isConversationAssignedToMe', () => {
  const currentUserId = 1;

  it('should return true when assigned to current user', () => {
    const message = { conversation: { assignee_id: 1 } };
    expect(isConversationAssignedToMe(message, currentUserId)).toBe(true);
  });

  it('should return false when assigned to different user', () => {
    const message = { conversation: { assignee_id: 2 } };
    expect(isConversationAssignedToMe(message, currentUserId)).toBe(false);
  });

  it('should return false when unassigned', () => {
    const message = { conversation: { assignee_id: null } };
    expect(isConversationAssignedToMe(message, currentUserId)).toBe(false);
  });

  it('should handle null message', () => {
    expect(isConversationAssignedToMe(null, currentUserId)).toBe(false);
  });
});

describe('isMessageFromCurrentUser', () => {
  const currentUserId = 1;

  it('should return true when message is from current user', () => {
    const message = { sender: { id: 1 } };
    expect(isMessageFromCurrentUser(message, currentUserId)).toBe(true);
  });

  it('should return false when message is from different user', () => {
    const message = { sender: { id: 2 } };
    expect(isMessageFromCurrentUser(message, currentUserId)).toBe(false);
  });

  it('should handle null message', () => {
    expect(isMessageFromCurrentUser(null, currentUserId)).toBe(false);
  });
});
