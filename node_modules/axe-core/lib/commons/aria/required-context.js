import standards from '../../standards';

/**
 * Get the required context (parent) roles for a given role
 * @method requiredContext
 * @memberof axe.commons.aria
 * @instance
 * @param {String} role The role to check
 * @return {Mixed} Either an Array of required context elements or `null` if there are none
 */
function requiredContext(role) {
  const roleDef = standards.ariaRoles[role];

  if (!roleDef || !Array.isArray(roleDef.requiredContext)) {
    return null;
  }

  return [...roleDef.requiredContext];
}

export default requiredContext;
