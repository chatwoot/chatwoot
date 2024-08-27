import {
  buildPermissionsFromRouter,
  getCurrentAccount,
  getUserPermissions,
  hasPermissions,
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
