import getAriaRolesByType from '../standards/get-aria-roles-by-type';

/**
 * Get the roles that have a certain "type"
 * @method getRolesByType
 * @memberof axe.commons.aria
 * @deprecated use standards/get-aria-roles-by-type
 * @instance
 * @param {String} roleType The roletype to check
 * @return {Array} Array of roles that match the type
 */
function getRolesByType(roleType) {
  return getAriaRolesByType(roleType);
}

export default getRolesByType;
