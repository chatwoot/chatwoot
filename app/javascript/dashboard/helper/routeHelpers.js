// eslint-disable-next-line default-param-last
export const getCurrentAccount = ({ accounts } = {}, accountId) => {
  return accounts.find(account => account.id === accountId);
};

// eslint-disable-next-line default-param-last
export const getUserRole = ({ accounts } = {}, accountId) => {
  const currentAccount = getCurrentAccount({ accounts }, accountId) || {};
  return currentAccount.role || null;
};

export const routeIsAccessibleFor = (route, role, roleWiseRoutes) => {
  return roleWiseRoutes[role].includes(route);
};

const validateActiveAccountRoutes = (to, user, roleWiseRoutes) => {
  // If the current account is active, then check for the route permissions
  const accountDashboardURL = `accounts/${to.params.accountId}/dashboard`;

  // If the user is trying to access suspended route, redirect them to dashboard
  if (to.name === 'account_suspended') {
    return accountDashboardURL;
  }

  const userRole = getUserRole(user, Number(to.params.accountId));
  const isAccessible = routeIsAccessibleFor(to.name, userRole, roleWiseRoutes);
  // If the route is not accessible for the user, return to dashboard screen
  return isAccessible ? null : accountDashboardURL;
};

export const validateLoggedInRoutes = (to, user, roleWiseRoutes) => {
  const currentAccount = getCurrentAccount(user, Number(to.params.accountId));

  // If current account is missing, either user does not have
  // access to the account or the account is deleted, return to login screen
  if (!currentAccount) {
    return `app/login`;
  }

  const isCurrentAccountActive = currentAccount.status === 'active';

  if (isCurrentAccountActive) {
    return validateActiveAccountRoutes(to, user, roleWiseRoutes);
  }

  // If the current account is not active, then redirect the user to the suspended screen
  if (to.name !== 'account_suspended') {
    return `accounts/${to.params.accountId}/suspended`;
  }

  // Proceed to the route if none of the above conditions are met
  return null;
};

export const isAConversationRoute = routeName =>
  [
    'inbox_conversation',
    'conversation_through_mentions',
    'conversation_through_unattended',
    'conversation_through_inbox',
    'conversations_through_label',
    'conversations_through_team',
    'conversations_through_folders',
    'conversation_through_participating',
  ].includes(routeName);

export const getConversationDashboardRoute = routeName => {
  switch (routeName) {
    case 'inbox_conversation':
      return 'home';
    case 'conversation_through_mentions':
      return 'conversation_mentions';
    case 'conversation_through_unattended':
      return 'conversation_unattended';
    case 'conversations_through_label':
      return 'label_conversations';
    case 'conversations_through_team':
      return 'team_conversations';
    case 'conversations_through_folders':
      return 'folder_conversations';
    case 'conversation_through_participating':
      return 'conversation_participating';
    case 'conversation_through_inbox':
      return 'inbox_dashboard';
    default:
      return null;
  }
};

export const isAInboxViewRoute = routeName =>
  ['inbox_view_conversation'].includes(routeName);
