import standards from '../../standards';

/**
 * Get required attributes for a given role
 * @method requiredAttr
 * @memberof axe.commons.aria
 * @instance
 * @param  {String} role The role to check
 * @return {Array}
 */
function requiredAttr(role) {
  const roleDef = standards.ariaRoles[role];

  if (!roleDef || !Array.isArray(roleDef.requiredAttrs)) {
    return [];
  }

  return [...roleDef.requiredAttrs];
}

export default requiredAttr;
