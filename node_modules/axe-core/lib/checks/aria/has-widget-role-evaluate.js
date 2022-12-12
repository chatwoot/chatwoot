import { getRoleType } from '../../commons/aria';

/**
 * Check if an elements `role` attribute uses any widget or composite role values.
 *
 * Widget roles are taken from the `ariaRoles` standards object from the roles `type` property.
 *
 * @memberof checks
 * @return {Boolean} True if the element uses a `widget` or `composite` role. False otherwise.
 */
function hasWidgetRoleEvaluate(node) {
  const role = node.getAttribute('role');
  if (role === null) {
    return false;
  }
  const roleType = getRoleType(role);
  return roleType === 'widget' || roleType === 'composite';
}

export default hasWidgetRoleEvaluate;
