import { describe, it, expect } from 'vitest';
import {
  applyRoleFilter,
  isStaleConversation,
  sortComparator,
} from '../helpers';

describe('Conversation Helpers', () => {
  describe('#isStaleConversation', () => {
    it('is stale when the incoming row is older than the stored one', () => {
      expect(
        isStaleConversation({ updated_at: 100 }, { updated_at: 200 })
      ).toBe(true);
    });

    it('is not stale when the incoming row is newer or the same age', () => {
      expect(
        isStaleConversation({ updated_at: 300 }, { updated_at: 200 })
      ).toBe(false);
      expect(
        isStaleConversation({ updated_at: 200 }, { updated_at: 200 })
      ).toBe(false);
    });

    it('is not stale when nothing is stored yet', () => {
      expect(isStaleConversation({ updated_at: 100 }, undefined)).toBe(false);
    });
  });

  describe('#sortComparator', () => {
    const older = { id: 1, last_activity_at: 1000 };
    const newer = { id: 2, last_activity_at: 2000 };

    it('keeps the requested sort when nothing is pinned', () => {
      expect(
        sortComparator(older, newer, 'last_activity_at_desc')
      ).toBeGreaterThan(0);
    });

    it('puts a pinned conversation before an unpinned one', () => {
      expect(
        sortComparator(older, newer, 'last_activity_at_desc', { 1: 500 })
      ).toBeLessThan(0);
    });

    it('puts an unpinned conversation after a pinned one', () => {
      expect(
        sortComparator(newer, older, 'last_activity_at_desc', { 1: 500 })
      ).toBeGreaterThan(0);
    });

    it('sorts two pinned conversations by the most recent pin', () => {
      expect(
        sortComparator(older, newer, 'last_activity_at_desc', {
          1: 500,
          2: 900,
        })
      ).toBeGreaterThan(0);
    });
  });

  describe('#applyRoleFilter', () => {
    // Test data for conversations
    const conversationWithAssignee = {
      meta: {
        assignee: {
          id: 1,
        },
      },
    };

    const conversationWithDifferentAssignee = {
      meta: {
        assignee: {
          id: 2,
        },
      },
    };

    const conversationWithoutAssignee = {
      meta: {
        assignee: null,
      },
    };

    // Test for administrator role
    it('always returns true for administrator role regardless of permissions', () => {
      const role = 'administrator';
      const permissions = [];
      const currentUserId = 1;

      expect(
        applyRoleFilter(
          conversationWithAssignee,
          role,
          permissions,
          currentUserId
        )
      ).toBe(true);
      expect(
        applyRoleFilter(
          conversationWithDifferentAssignee,
          role,
          permissions,
          currentUserId
        )
      ).toBe(true);
      expect(
        applyRoleFilter(
          conversationWithoutAssignee,
          role,
          permissions,
          currentUserId
        )
      ).toBe(true);
    });

    // Test for agent role
    it('always returns true for agent role regardless of permissions', () => {
      const role = 'agent';
      const permissions = [];
      const currentUserId = 1;

      expect(
        applyRoleFilter(
          conversationWithAssignee,
          role,
          permissions,
          currentUserId
        )
      ).toBe(true);
      expect(
        applyRoleFilter(
          conversationWithDifferentAssignee,
          role,
          permissions,
          currentUserId
        )
      ).toBe(true);
      expect(
        applyRoleFilter(
          conversationWithoutAssignee,
          role,
          permissions,
          currentUserId
        )
      ).toBe(true);
    });

    // Test for custom role with 'conversation_manage' permission
    it('returns true for any user with conversation_manage permission', () => {
      const role = 'custom_role';
      const permissions = ['conversation_manage'];
      const currentUserId = 1;

      expect(
        applyRoleFilter(
          conversationWithAssignee,
          role,
          permissions,
          currentUserId
        )
      ).toBe(true);
      expect(
        applyRoleFilter(
          conversationWithDifferentAssignee,
          role,
          permissions,
          currentUserId
        )
      ).toBe(true);
      expect(
        applyRoleFilter(
          conversationWithoutAssignee,
          role,
          permissions,
          currentUserId
        )
      ).toBe(true);
    });

    // Test for custom role with 'conversation_unassigned_manage' permission
    describe('with conversation_unassigned_manage permission', () => {
      const role = 'custom_role';
      const permissions = ['conversation_unassigned_manage'];
      const currentUserId = 1;

      it('returns true for conversations assigned to the user', () => {
        expect(
          applyRoleFilter(
            conversationWithAssignee,
            role,
            permissions,
            currentUserId
          )
        ).toBe(true);
      });

      it('returns true for unassigned conversations', () => {
        expect(
          applyRoleFilter(
            conversationWithoutAssignee,
            role,
            permissions,
            currentUserId
          )
        ).toBe(true);
      });

      it('returns false for conversations assigned to other users', () => {
        expect(
          applyRoleFilter(
            conversationWithDifferentAssignee,
            role,
            permissions,
            currentUserId
          )
        ).toBe(false);
      });
    });

    // Test for custom role with 'conversation_participating_manage' permission
    describe('with conversation_participating_manage permission', () => {
      const role = 'custom_role';
      const permissions = ['conversation_participating_manage'];
      const currentUserId = 1;

      it('returns true for conversations assigned to the user', () => {
        expect(
          applyRoleFilter(
            conversationWithAssignee,
            role,
            permissions,
            currentUserId
          )
        ).toBe(true);
      });

      it('returns false for unassigned conversations', () => {
        expect(
          applyRoleFilter(
            conversationWithoutAssignee,
            role,
            permissions,
            currentUserId
          )
        ).toBe(false);
      });

      it('returns false for conversations assigned to other users', () => {
        expect(
          applyRoleFilter(
            conversationWithDifferentAssignee,
            role,
            permissions,
            currentUserId
          )
        ).toBe(false);
      });
    });

    // Test for user with no relevant permissions
    it('returns false for custom role without any relevant permissions', () => {
      const role = 'custom_role';
      const permissions = ['some_other_permission'];
      const currentUserId = 1;

      expect(
        applyRoleFilter(
          conversationWithAssignee,
          role,
          permissions,
          currentUserId
        )
      ).toBe(false);
      expect(
        applyRoleFilter(
          conversationWithDifferentAssignee,
          role,
          permissions,
          currentUserId
        )
      ).toBe(false);
      expect(
        applyRoleFilter(
          conversationWithoutAssignee,
          role,
          permissions,
          currentUserId
        )
      ).toBe(false);
    });

    // `conversation_unassigned_manage` is scoped on the server by `conversations.unassigned`,
    // which requires `assignee_agent_bot_id` to be null: a bot-held conversation is never granted
    // through it.
    it('treats a bot-held conversation as assigned', () => {
      const conversation = {
        meta: { assignee: { id: 99, name: 'Bot' }, assignee_type: 'AgentBot' },
      };
      expect(
        applyRoleFilter(
          conversation,
          'custom_role',
          ['conversation_unassigned_manage'],
          1
        )
      ).toBe(false);
    });

    // The other half of the same payload: the server grants "mine" through `assigned_to(user)`,
    // which reads `assignee_id` and can only name a human, so a bot sharing the agent's integer
    // grants nothing. Both scoped roles ask the question, so both are checked.
    it.each([
      'conversation_unassigned_manage',
      'conversation_participating_manage',
    ])('keeps a bot sharing the agent id out of %s', permission => {
      const conversation = {
        meta: { assignee: { id: 1, name: 'Bot' }, assignee_type: 'AgentBot' },
      };
      expect(
        applyRoleFilter(conversation, 'custom_role', [permission], 1)
      ).toBe(false);
    });

    // Test edge cases for meta.assignee
    describe('handles edge cases with meta.assignee', () => {
      const role = 'custom_role';
      const permissions = ['conversation_unassigned_manage'];
      const currentUserId = 1;

      it('treats undefined assignee as unassigned', () => {
        const conversationWithUndefinedAssignee = {
          meta: {
            assignee: undefined,
          },
        };

        expect(
          applyRoleFilter(
            conversationWithUndefinedAssignee,
            role,
            permissions,
            currentUserId
          )
        ).toBe(true);
      });

      it('handles empty meta object', () => {
        const conversationWithEmptyMeta = {
          meta: {},
        };

        expect(
          applyRoleFilter(
            conversationWithEmptyMeta,
            role,
            permissions,
            currentUserId
          )
        ).toBe(true);
      });
    });
  });
});
