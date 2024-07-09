import { hasPermissions } from './permissionsHelper';

// eslint-disable-next-line default-param-last
export const getCurrentAccount = ({ accounts } = {}, accountId) => {
  return accounts.find(account => account.id === accountId);
};

export const routeIsAccessibleFor = (route, userPermissions = []) => {
  const { meta: { permissions: routePermissions = [] } = {} } = route;
  return hasPermissions(routePermissions, userPermissions);
};

const validateActiveAccountRoutes = (to, user) => {
  // If the current account is active, then check for the route permissions
  const accountDashboardURL = `accounts/${to.params.accountId}/dashboard`;

  // If the user is trying to access suspended route, redirect them to dashboard
  if (to.name === 'account_suspended') {
    return accountDashboardURL;
  }

  const isAccessible = routeIsAccessibleFor(to, user.permissions);
  // If the route is not accessible for the user, return to dashboard screen
  return isAccessible ? null : accountDashboardURL;
};

export const validateLoggedInRoutes = (to, user) => {
  const currentAccount = getCurrentAccount(user, Number(to.params.accountId));
  // If current account is missing, either user does not have
  // access to the account or the account is deleted, return to login screen
  if (!currentAccount) {
    return `app/login`;
  }

  const isCurrentAccountActive = currentAccount.status === 'active';

  if (isCurrentAccountActive) {
    return validateActiveAccountRoutes(to, user);
  }

  // If the current account is not active, then redirect the user to the suspended screen
  if (to.name !== 'account_suspended') {
    return `accounts/${to.params.accountId}/suspended`;
  }

  // Proceed to the route if none of the above conditions are met
  return null;
};

export const isAConversationRoute = (
  routeName,
  includeBase = false,
  includeExtended = true
) => {
  const baseRoutes = [
    'home',
    'conversation_mentions',
    'conversation_unattended',
    'inbox_dashboard',
    'label_conversations',
    'team_conversations',
    'folder_conversations',
    'conversation_participating',
  ];
  const extendedRoutes = [
    'inbox_conversation',
    'conversation_through_mentions',
    'conversation_through_unattended',
    'conversation_through_inbox',
    'conversations_through_label',
    'conversations_through_team',
    'conversations_through_folders',
    'conversation_through_participating',
  ];

  const routes = [
    ...(includeBase ? baseRoutes : []),
    ...(includeExtended ? extendedRoutes : []),
  ];

  return routes.includes(routeName);
};

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

export const isAInboxViewRoute = (routeName, includeBase = false) => {
  const baseRoutes = ['inbox_view'];
  const extendedRoutes = ['inbox_view_conversation'];
  const routeNames = includeBase
    ? [...baseRoutes, ...extendedRoutes]
    : extendedRoutes;
  return routeNames.includes(routeName);
};

export const isNotificationRoute = routeName =>
  routeName === 'notifications_index';
