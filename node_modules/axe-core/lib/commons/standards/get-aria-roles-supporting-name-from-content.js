import cache from '../../core/base/cache';
import standards from '../../standards';

/**
 * Return a list of aria roles which are name from content.
 * @return {String[]} List of all roles with name from content
 */
function getAriaRolesSupportingNameFromContent() {
  if (cache.get('ariaRolesNameFromContent')) {
    return cache.get('ariaRolesNameFromContent');
  }

  const contentRoles = Object.keys(standards.ariaRoles).filter(roleName => {
    return standards.ariaRoles[roleName].nameFromContent;
  });

  cache.set('ariaRolesNameFromContent', contentRoles);

  return contentRoles;
}

export default getAriaRolesSupportingNameFromContent;
