import {
  buildPermissionsFromRouter,
  getCurrentAccount,
  getUserPermissions,
  hasPermissions,
  filterItemsByPermission,
} from '../permissionsHelper';

describe('#getCurrentAccount', () => {
  it('should return the current account', () => {
    expect(getCurrentAccount({ accounts: [{ id: 1 }] }, 1)).toEqual({ id: 1 });
    expect(getCurrentAccount({ accounts: [] }, 1)).toEqual(undefined);
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

describe('buildPermissionsFromRouter', () => {
  it('returns a valid object when routes have permissions defined', () => {
    expect(
      buildPermissionsFromRouter([
        {
          path: 'agent',
          name: 'agent_list',
          meta: { permissions: ['agent_admin'] },
        },
        {
          path: 'inbox',
          children: [
            {
              path: '',
              name: 'inbox_list',
              meta: { permissions: ['inbox_admin'] },
            },
          ],
        },
        {
          path: 'conversations',
          children: [
            {
              path: '',
              children: [
                {
                  path: 'attachments',
                  name: 'attachments_list',
                  meta: { permissions: ['conversation_admin'] },
                },
              ],
            },
          ],
        },
      ])
    ).toEqual({
      agent_list: ['agent_admin'],
      inbox_list: ['inbox_admin'],
      attachments_list: ['conversation_admin'],
    });
  });

  it('throws an error if a named routed does not have permissions defined', () => {
    expect(() => {
      buildPermissionsFromRouter([
        {
          path: 'agent',
          name: 'agent_list',
        },
      ]);
    }).toThrow("The route doesn't have the required permissions defined");

    expect(() => {
      buildPermissionsFromRouter([
        {
          path: 'agent',
          name: 'agent_list',
          meta: {},
        },
      ]);
    }).toThrow("The route doesn't have the required permissions defined");
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
