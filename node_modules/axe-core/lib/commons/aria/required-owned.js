import standards from '../../standards';

/**
 * Get the required owned (children) roles for a given role
 * @method requiredOwned
 * @memberof axe.commons.aria
 * @instance
 * @param {String} role The role to check
 * @return {Mixed} Either an Array of required owned elements or `null` if there are none
 */
function requiredOwned(role) {
  const roleDef = standards.ariaRoles[role];

  if (!roleDef || !Array.isArray(roleDef.requiredOwned)) {
    return null;
  }

  return [...roleDef.requiredOwned];
}

export default requiredOwned;
