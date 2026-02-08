import { describe, it, expect } from 'vitest';
import { applyRoleFilter } from '../helpers';

describe('Conversation Helpers', () => {
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
