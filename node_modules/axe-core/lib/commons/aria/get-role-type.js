import standards from '../../standards';

/**
 * Get the "type" of role; either widget, composite, abstract, landmark or `null`
 * @method getRoleType
 * @memberof axe.commons.aria
 * @instance
 * @param {String} role The role to check
 * @return {Mixed} String if a matching role and its type are found, otherwise `null`
 */
function getRoleType(role) {
  const roleDef = standards.ariaRoles[role];

  if (!roleDef) {
    return null;
  }

  return roleDef.type;
}

export default getRoleType;
