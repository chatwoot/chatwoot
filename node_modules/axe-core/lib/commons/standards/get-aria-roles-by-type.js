import standards from '../../standards';

/**
 * Return a list of aria roles whose type matches the provided value.
 * @param {String} type The desired role type
 * @return {String[]} List of all roles matching the type
 */
function getAriaRolesByType(type) {
  return Object.keys(standards.ariaRoles).filter(roleName => {
    return standards.ariaRoles[roleName].type === type;
  });
}

export default getAriaRolesByType;
