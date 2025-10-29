import {
  getConversationDashboardRoute,
  isAConversationRoute,
  defaultRedirectPage,
  routeIsAccessibleFor,
  validateLoggedInRoutes,
  isAInboxViewRoute,
} from '../routeHelpers';

describe('#routeIsAccessibleFor', () => {
  it('should return the correct access', () => {
    let route = { meta: { permissions: ['administrator'] } };
    expect(routeIsAccessibleFor(route, ['agent'])).toEqual(false);
    expect(routeIsAccessibleFor(route, ['administrator'])).toEqual(true);
  });
});

describe('#defaultRedirectPage', () => {
  const to = {
    params: { accountId: '2' },
    fullPath: '/app/accounts/2/dashboard',
    name: 'home',
  };

  it('should return dashboard route for users with conversation permissions', () => {
    const permissions = ['conversation_manage', 'agent'];
    expect(defaultRedirectPage(to, permissions)).toBe('accounts/2/dashboard');
  });

  it('should return contacts route for users with contact permissions', () => {
    const permissions = ['contact_manage'];
    expect(defaultRedirectPage(to, permissions)).toBe('accounts/2/contacts');
  });

  it('should return reports route for users with report permissions', () => {
    const permissions = ['report_manage'];
    expect(defaultRedirectPage(to, permissions)).toBe(
      'accounts/2/reports/overview'
    );
  });

  it('should return portals route for users with portal permissions', () => {
    const permissions = ['knowledge_base_manage'];
    expect(defaultRedirectPage(to, permissions)).toBe('accounts/2/portals');
  });

  it('should return dashboard route as default for users with custom roles', () => {
    const permissions = ['custom_role'];
    expect(defaultRedirectPage(to, permissions)).toBe('accounts/2/dashboard');
  });

  it('should return dashboard route for users with administrator role', () => {
    const permissions = ['administrator'];
    expect(defaultRedirectPage(to, permissions)).toBe('accounts/2/dashboard');
  });

  it('should return dashboard route for users with multiple permissions', () => {
    const permissions = [
      'contact_manage',
      'custom_role',
      'conversation_manage',
      'agent',
      'administrator',
    ];
    expect(defaultRedirectPage(to, permissions)).toBe('accounts/2/dashboard');
  });
});

describe('#validateLoggedInRoutes', () => {
  describe('when account access is missing', () => {
    it('should return the login route', () => {
      expect(
        validateLoggedInRoutes({ params: { accountId: 1 } }, { accounts: [] })
      ).toEqual(`app/login`);
    });
  });
  describe('when account access is available', () => {
    describe('when account is suspended', () => {
      it('return suspended route', () => {
        expect(
          validateLoggedInRoutes(
            {
              name: 'conversations',
              params: { accountId: 1 },
              meta: { permissions: ['agent'] },
            },
            { accounts: [{ id: 1, role: 'agent', status: 'suspended' }] }
          )
        ).toEqual(`accounts/1/suspended`);
      });
    });
    describe('when account is active', () => {
      describe('when route is accessible', () => {
        it('returns null (no action required)', () => {
          expect(
            validateLoggedInRoutes(
              {
                name: 'conversations',
                params: { accountId: 1 },
                meta: { permissions: ['agent'] },
              },
              {
                permissions: ['agent'],
                accounts: [
                  {
                    id: 1,
                    role: 'agent',
                    permissions: ['agent'],
                    status: 'active',
                  },
                ],
              }
            )
          ).toEqual(null);
        });
      });
      describe('when route is not accessible', () => {
        it('returns dashboard url', () => {
          expect(
            validateLoggedInRoutes(
              {
                name: 'billing',
                params: { accountId: 1 },
                meta: { permissions: ['administrator'] },
              },
              { accounts: [{ id: 1, role: 'agent', status: 'active' }] }
            )
          ).toEqual(`accounts/1/dashboard`);
        });
      });
      describe('when route is suspended route', () => {
        it('returns dashboard url', () => {
          expect(
            validateLoggedInRoutes(
              { name: 'account_suspended', params: { accountId: 1 } },
              { accounts: [{ id: 1, role: 'agent', status: 'active' }] }
            )
          ).toEqual(`accounts/1/dashboard`);
        });
      });
    });
  });
});

describe('isAConversationRoute', () => {
  it('returns true if conversation route name is provided', () => {
    expect(isAConversationRoute('inbox_conversation')).toBe(true);
    expect(isAConversationRoute('conversation_through_inbox')).toBe(true);
    expect(isAConversationRoute('conversations_through_label')).toBe(true);
    expect(isAConversationRoute('conversations_through_team')).toBe(true);
    expect(isAConversationRoute('dashboard')).toBe(false);
  });

  it('returns true if base conversation route name is provided and includeBase is true', () => {
    expect(isAConversationRoute('home', true)).toBe(true);
    expect(isAConversationRoute('conversation_mentions', true)).toBe(true);
    expect(isAConversationRoute('conversation_unattended', true)).toBe(true);
    expect(isAConversationRoute('inbox_dashboard', true)).toBe(true);
    expect(isAConversationRoute('label_conversations', true)).toBe(true);
    expect(isAConversationRoute('team_conversations', true)).toBe(true);
    expect(isAConversationRoute('folder_conversations', true)).toBe(true);
    expect(isAConversationRoute('conversation_participating', true)).toBe(true);
  });

  it('returns false if base conversation route name is provided and includeBase is false', () => {
    expect(isAConversationRoute('home', false)).toBe(false);
    expect(isAConversationRoute('conversation_mentions', false)).toBe(false);
    expect(isAConversationRoute('conversation_unattended', false)).toBe(false);
    expect(isAConversationRoute('inbox_dashboard', false)).toBe(false);
    expect(isAConversationRoute('label_conversations', false)).toBe(false);
    expect(isAConversationRoute('team_conversations', false)).toBe(false);
    expect(isAConversationRoute('folder_conversations', false)).toBe(false);
    expect(isAConversationRoute('conversation_participating', false)).toBe(
      false
    );
  });

  it('returns true if base conversation route name is provided and includeBase and includeExtended is true', () => {
    expect(isAConversationRoute('home', true, true)).toBe(true);
    expect(isAConversationRoute('conversation_mentions', true, true)).toBe(
      true
    );
    expect(isAConversationRoute('conversation_unattended', true, true)).toBe(
      true
    );
    expect(isAConversationRoute('inbox_dashboard', true, true)).toBe(true);
    expect(isAConversationRoute('label_conversations', true, true)).toBe(true);
    expect(isAConversationRoute('team_conversations', true, true)).toBe(true);
    expect(isAConversationRoute('folder_conversations', true, true)).toBe(true);
    expect(isAConversationRoute('conversation_participating', true, true)).toBe(
      true
    );
  });

  it('returns false if base conversation route name is not provided', () => {
    expect(isAConversationRoute('')).toBe(false);
  });
});

describe('getConversationDashboardRoute', () => {
  it('returns dashboard route for conversation', () => {
    expect(getConversationDashboardRoute('inbox_conversation')).toEqual('home');
    expect(
      getConversationDashboardRoute('conversation_through_mentions')
    ).toEqual('conversation_mentions');
    expect(
      getConversationDashboardRoute('conversation_through_unattended')
    ).toEqual('conversation_unattended');
    expect(
      getConversationDashboardRoute('conversations_through_label')
    ).toEqual('label_conversations');
    expect(getConversationDashboardRoute('conversations_through_team')).toEqual(
      'team_conversations'
    );
    expect(
      getConversationDashboardRoute('conversations_through_folders')
    ).toEqual('folder_conversations');
    expect(
      getConversationDashboardRoute('conversation_through_participating')
    ).toEqual('conversation_participating');
    expect(getConversationDashboardRoute('conversation_through_inbox')).toEqual(
      'inbox_dashboard'
    );
    expect(getConversationDashboardRoute('non_existent_route')).toBeNull();
  });
});

describe('isAInboxViewRoute', () => {
  it('returns true if inbox view route name is provided', () => {
    expect(isAInboxViewRoute('inbox_view_conversation')).toBe(true);
    expect(isAInboxViewRoute('inbox_conversation')).toBe(false);
  });

  it('returns true if base inbox view route name is provided and includeBase is true', () => {
    expect(isAInboxViewRoute('inbox_view', true)).toBe(true);
  });

  it('returns false if base inbox view route name is provided and includeBase is false', () => {
    expect(isAInboxViewRoute('inbox_view')).toBe(false);
  });
});
