import standards from '../../standards';
import getGlobalAriaAttrs from '../standards/get-global-aria-attrs';

/**
 * Get allowed attributes for a given role
 * @method allowedAttr
 * @memberof axe.commons.aria
 * @instance
 * @param  {String} role The role to check
 * @return {Array}
 */
function allowedAttr(role) {
  const roleDef = standards.ariaRoles[role];
  const attrs = [...getGlobalAriaAttrs()];

  if (!roleDef) {
    return attrs;
  }

  if (roleDef.allowedAttrs) {
    attrs.push(...roleDef.allowedAttrs);
  }

  if (roleDef.requiredAttrs) {
    attrs.push(...roleDef.requiredAttrs);
  }

  return attrs;
}

export default allowedAttr;
