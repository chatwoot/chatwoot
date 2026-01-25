export const hasPermissions = (
  requiredPermissions = [],
  availablePermissions = []
) => {
  // CommMate: Administrators have access to everything
  if (availablePermissions.includes('administrator')) {
    return true;
  }
  return requiredPermissions.some(permission =>
    availablePermissions.includes(permission)
  );
};

export const getCurrentAccount = ({ accounts } = {}, accountId = null) => {
  return accounts.find(account => Number(account.id) === Number(accountId));
};

export const getUserPermissions = (user, accountId) => {
  // CommMate: Handle case where accountId is not yet available (route transitions)
  // Return empty array which will be treated as "no restrictions" by hasMenuPermission
  if (!accountId || !user?.accounts?.length) {
    // If user has only one account and is admin, assume admin permissions
    // This prevents menu flickering during initial load
    if (user?.accounts?.length === 1 && user.accounts[0].role === 'administrator') {
      return ['administrator'];
    }
    return [];
  }
  
  const currentAccount = getCurrentAccount(user, accountId) || {};
  const permissions = currentAccount.permissions || [];
  // CommMate: Include 'administrator' in permissions if user has administrator role
  if (currentAccount.role === 'administrator' && !permissions.includes('administrator')) {
    return ['administrator', ...permissions];
  }
  return permissions;
};

export const getUserRole = (user, accountId) => {
  const currentAccount = getCurrentAccount(user, accountId) || {};
  // CommMate: Simplified role - no longer uses custom_role_id
  return currentAccount.role || 'agent';
};

/**
 * Filters and transforms items based on user permissions.
 *
 * @param {Object} items - An object containing items to be filtered.
 * @param {Array} userPermissions - Array of permissions the user has.
 * @param {Function} getPermissions - Function to extract required permissions from an item.
 * @param {Function} [transformItem] - Optional function to transform each item after filtering.
 * @returns {Array} Filtered and transformed items.
 */
export const filterItemsByPermission = (
  items,
  userPermissions,
  getPermissions,
  transformItem = (key, item) => ({ key, ...item })
) => {
  // Helper function to check if an item has the required permissions
  const hasRequiredPermissions = item => {
    const requiredPermissions = getPermissions(item);
    return (
      requiredPermissions.length === 0 ||
      hasPermissions(requiredPermissions, userPermissions)
    );
  };

  return Object.entries(items)
    .filter(([, item]) => hasRequiredPermissions(item)) // Keep only items with required permissions
    .map(([key, item]) => transformItem(key, item)); // Transform each remaining item
};
