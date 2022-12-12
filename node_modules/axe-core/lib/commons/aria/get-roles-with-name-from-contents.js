import getAriaRolesSupportingNameFromContent from '../standards/get-aria-roles-supporting-name-from-content';

/**
 * Get the roles that get name from the element's contents
 * @method getRolesWithNameFromContents
 * @memberof axe.commons.aria
 * @instance
 * @deprecated use standards/get-aria-roles-supporting-name-from-content
 * @return {Array} Array of roles that match the type
 */
function getRolesWithNameFromContents() {
  return getAriaRolesSupportingNameFromContent();
}

export default getRolesWithNameFromContents;
