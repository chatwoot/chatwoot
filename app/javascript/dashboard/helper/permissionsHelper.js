import wootConstants from 'dashboard/constants/globals';
import { ASSIGNEE_TYPE_TAB_PERMISSIONS } from 'dashboard/constants/permissions';

export const hasPermissions = (
  requiredPermissions = [],
  availablePermissions = []
) => {
  return requiredPermissions.some(permission =>
    availablePermissions.includes(permission)
  );
};

export const getCurrentAccount = ({ accounts } = {}, accountId = null) => {
  return accounts.find(account => Number(account.id) === Number(accountId));
};

export const getUserPermissions = (user, accountId) => {
  const currentAccount = getCurrentAccount(user, accountId) || {};
  return currentAccount.permissions || [];
};

// Features this member may use (`FeatureAccess` on the server), kept apart from the native
// `permissions` so that granting one never opens a native page.
export const getFeatureAccess = (user, accountId) => {
  const currentAccount = getCurrentAccount(user, accountId) || {};
  return currentAccount.feature_access || [];
};

export const hasFeatureAccess = (user, accountId, capability) => {
  if (!capability) return true;
  return getFeatureAccess(user, accountId).includes(capability);
};

export const getUserRole = (user, accountId) => {
  const currentAccount = getCurrentAccount(user, accountId) || {};
  // A role in force, as the server reports it: without Enterprise, or with the role deleted,
  // a `custom_role_id` left on the row grants nothing and the member is a plain agent.
  if (
    currentAccount.custom_role_id &&
    (currentAccount.permissions || []).includes('custom_role')
  ) {
    return 'custom_role';
  }

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

/**
 * Resolves which conversation assignee tabs (Mine/Unassigned/All) a user may
 * see, applying the account-level hide-tabs toggles for basic agents.
 *
 * Mention/Participating views are scoped to conversations the user can already
 * see, so the toggles must not apply there: hiding Unassigned/All would strand
 * chats not assigned to the agent under an unreachable tab. Admins and custom
 * roles are never affected.
 *
 * @param {Object} params
 * @param {String} params.conversationType - Current view type (mention/participating/...).
 * @param {String} params.userRole - Resolved user role for the account.
 * @param {Object} [params.accountSettings] - Account settings holding the toggles.
 * @returns {Object} The visible subset of ASSIGNEE_TYPE_TAB_PERMISSIONS.
 */
export const getVisibleAssigneeTabPermissions = ({
  conversationType,
  userRole,
  accountSettings = {},
} = {}) => {
  const { MENTION, PARTICIPATING } = wootConstants.CONVERSATION_TYPE;
  const isPersonalScopeView = [MENTION, PARTICIPATING].includes(
    conversationType
  );

  if (isPersonalScopeView || userRole !== 'agent') {
    return ASSIGNEE_TYPE_TAB_PERMISSIONS;
  }

  const hideUnassigned = Boolean(accountSettings.hide_agent_unassigned_tab);
  const hideAll = hideUnassigned || Boolean(accountSettings.hide_agent_all_tab);

  if (!hideUnassigned && !hideAll) return ASSIGNEE_TYPE_TAB_PERMISSIONS;

  const { unassigned, all, ...rest } = ASSIGNEE_TYPE_TAB_PERMISSIONS;
  return {
    ...rest,
    ...(hideUnassigned ? {} : { unassigned }),
    ...(hideAll ? {} : { all }),
  };
};

/**
 * Resolves whether the user may delete messages, applying the account-level
 * toggle that blocks deletion for basic agents. Admins and custom roles are
 * never affected.
 *
 * The UI gate mirrors `MessagePolicy#destroy?` — hiding the option is a
 * convenience, the endpoint enforces the same rule.
 *
 * @param {Object} params
 * @param {String} params.userRole - Resolved user role for the account.
 * @param {Object} [params.accountSettings] - Account settings holding the toggle.
 * @returns {Boolean} Whether message deletion is allowed.
 */
export const canDeleteMessages = ({ userRole, accountSettings = {} } = {}) => {
  if (userRole !== 'agent') return true;

  return !accountSettings.disable_agent_message_deletion;
};
