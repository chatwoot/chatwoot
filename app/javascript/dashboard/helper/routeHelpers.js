export const getCurrentAccount = ({ accounts } = {}, accountId) => {
  return accounts.find(account => account.id === accountId);
};

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
