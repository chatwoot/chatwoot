import {
  getCurrentAccount,
  getUserRole,
  getUserPermissions,
  hasPermissions,
  filterItemsByPermission,
  getVisibleAssigneeTabPermissions,
  canDeleteMessages,
} from '../permissionsHelper';
import { ASSIGNEE_TYPE_TAB_PERMISSIONS } from 'dashboard/constants/permissions';

describe('#getCurrentAccount', () => {
  it('should return the current account', () => {
    expect(getCurrentAccount({ accounts: [{ id: 1 }] }, 1)).toEqual({ id: 1 });
    expect(getCurrentAccount({ accounts: [] }, 1)).toEqual(undefined);
  });
});

describe('#getUserRole', () => {
  const user = permissions => ({
    accounts: [{ id: 1, role: 'agent', custom_role_id: 7, permissions }],
  });

  it('reads a custom role the server reports as in force', () => {
    expect(getUserRole(user(['conversation_manage', 'custom_role']), 1)).toBe(
      'custom_role'
    );
  });

  // The id outlives the role when Enterprise is not loaded or the role was deleted; the
  // server then reports a plain agent, and the dashboard has to agree.
  it('reads a leftover custom role id as the role it really is', () => {
    expect(getUserRole(user(['agent']), 1)).toBe('agent');
  });
});

describe('#getUserPermissions', () => {
  it('should return the correct permissions', () => {
    const user = {
      accounts: [
        { id: 1, permissions: ['conversations_manage'] },
        { id: 3, permissions: ['contacts_manage'] },
      ],
    };
    expect(getUserPermissions(user, 1)).toEqual(['conversations_manage']);
    expect(getUserPermissions(user, '3')).toEqual(['contacts_manage']);
    expect(getUserPermissions(user, 2)).toEqual([]);
  });
});

describe('hasPermissions', () => {
  it('returns true if permission is present', () => {
    expect(
      hasPermissions(['contact_manage'], ['team_manage', 'contact_manage'])
    ).toBe(true);
  });

  it('returns true if permission is not present', () => {
    expect(
      hasPermissions(['contact_manage'], ['team_manage', 'user_manage'])
    ).toBe(false);
    expect(hasPermissions()).toBe(false);
    expect(hasPermissions([])).toBe(false);
  });
});

describe('filterItemsByPermission', () => {
  const items = {
    item1: { name: 'Item 1', permissions: ['agent', 'administrator'] },
    item2: {
      name: 'Item 2',
      permissions: [
        'conversation_manage',
        'conversation_unassigned_manage',
        'conversation_participating_manage',
      ],
    },
    item3: { name: 'Item 3', permissions: ['contact_manage'] },
    item4: { name: 'Item 4', permissions: ['report_manage'] },
    item5: { name: 'Item 5', permissions: ['knowledge_base_manage'] },
    item6: {
      name: 'Item 6',
      permissions: [
        'agent',
        'administrator',
        'conversation_manage',
        'conversation_unassigned_manage',
        'conversation_participating_manage',
        'contact_manage',
        'report_manage',
        'knowledge_base_manage',
      ],
    },
    item7: { name: 'Item 7', permissions: [] },
  };

  const getPermissions = item => item.permissions;

  it('filters items based on user permissions', () => {
    const userPermissions = ['agent', 'contact_manage', 'report_manage'];
    const result = filterItemsByPermission(
      items,
      userPermissions,
      getPermissions
    );

    expect(result).toHaveLength(5);
    expect(result).toContainEqual(
      expect.objectContaining({ key: 'item1', name: 'Item 1' })
    );
    expect(result).toContainEqual(
      expect.objectContaining({ key: 'item3', name: 'Item 3' })
    );
    expect(result).toContainEqual(
      expect.objectContaining({ key: 'item4', name: 'Item 4' })
    );
    expect(result).toContainEqual(
      expect.objectContaining({ key: 'item6', name: 'Item 6' })
    );
  });

  it('includes items with empty permissions', () => {
    const userPermissions = [];
    const result = filterItemsByPermission(
      items,
      userPermissions,
      getPermissions
    );

    expect(result).toHaveLength(1);
    expect(result).toContainEqual(
      expect.objectContaining({ key: 'item7', name: 'Item 7' })
    );
  });

  it('uses custom transform function when provided', () => {
    const userPermissions = ['agent', 'contact_manage'];
    const customTransform = (key, item) => ({ id: key, title: item.name });
    const result = filterItemsByPermission(
      items,
      userPermissions,
      getPermissions,
      customTransform
    );

    expect(result).toHaveLength(4);
    expect(result).toContainEqual({ id: 'item1', title: 'Item 1' });
    expect(result).toContainEqual({ id: 'item3', title: 'Item 3' });
    expect(result).toContainEqual({ id: 'item6', title: 'Item 6' });
  });

  it('handles empty items object', () => {
    const result = filterItemsByPermission({}, ['agent'], getPermissions);

    expect(result).toHaveLength(0);
  });

  it('handles custom getPermissions function', () => {
    const customItems = {
      item1: { name: 'Item 1', requiredPerms: ['agent', 'administrator'] },
      item2: { name: 'Item 2', requiredPerms: ['contact_manage'] },
    };
    const customGetPermissions = item => item.requiredPerms;
    const result = filterItemsByPermission(
      customItems,
      ['agent'],
      customGetPermissions
    );

    expect(result).toHaveLength(1);
    expect(result).toContainEqual(
      expect.objectContaining({ key: 'item1', name: 'Item 1' })
    );
  });
});

describe('#getVisibleAssigneeTabPermissions', () => {
  const hideBoth = {
    hide_agent_unassigned_tab: true,
    hide_agent_all_tab: true,
  };

  it('returns all tabs for non-agent roles regardless of settings', () => {
    expect(
      getVisibleAssigneeTabPermissions({
        userRole: 'administrator',
        accountSettings: hideBoth,
      })
    ).toEqual(ASSIGNEE_TYPE_TAB_PERMISSIONS);
  });

  it('returns all tabs for agents when no toggle is set', () => {
    expect(
      getVisibleAssigneeTabPermissions({
        userRole: 'agent',
        accountSettings: {},
      })
    ).toEqual(ASSIGNEE_TYPE_TAB_PERMISSIONS);
  });

  it('hides unassigned and all when unassigned toggle is on', () => {
    const result = getVisibleAssigneeTabPermissions({
      userRole: 'agent',
      accountSettings: { hide_agent_unassigned_tab: true },
    });

    expect(Object.keys(result)).toEqual(['me']);
  });

  it('hides only all when the all toggle is on by itself', () => {
    const result = getVisibleAssigneeTabPermissions({
      userRole: 'agent',
      accountSettings: { hide_agent_all_tab: true },
    });

    expect(Object.keys(result)).toEqual(['me', 'unassigned']);
  });

  it('keeps all tabs on the mention view even with toggles on', () => {
    expect(
      getVisibleAssigneeTabPermissions({
        conversationType: 'mention',
        userRole: 'agent',
        accountSettings: hideBoth,
      })
    ).toEqual(ASSIGNEE_TYPE_TAB_PERMISSIONS);
  });

  it('keeps all tabs on the participating view even with toggles on', () => {
    expect(
      getVisibleAssigneeTabPermissions({
        conversationType: 'participating',
        userRole: 'agent',
        accountSettings: hideBoth,
      })
    ).toEqual(ASSIGNEE_TYPE_TAB_PERMISSIONS);
  });

  it('still applies toggles on the unattended view', () => {
    const result = getVisibleAssigneeTabPermissions({
      conversationType: 'unattended',
      userRole: 'agent',
      accountSettings: hideBoth,
    });

    expect(Object.keys(result)).toEqual(['me']);
  });
});

describe('#canDeleteMessages', () => {
  const blocked = { disable_agent_message_deletion: true };

  it('allows agents when the toggle is off', () => {
    expect(canDeleteMessages({ userRole: 'agent', accountSettings: {} })).toBe(
      true
    );
  });

  it('blocks agents when the toggle is on', () => {
    expect(
      canDeleteMessages({ userRole: 'agent', accountSettings: blocked })
    ).toBe(false);
  });

  it('allows administrators even when the toggle is on', () => {
    expect(
      canDeleteMessages({ userRole: 'administrator', accountSettings: blocked })
    ).toBe(true);
  });

  it('allows custom roles even when the toggle is on', () => {
    expect(
      canDeleteMessages({ userRole: 'custom_role', accountSettings: blocked })
    ).toBe(true);
  });

  it('allows deletion when called without arguments', () => {
    expect(canDeleteMessages()).toBe(true);
  });
});
