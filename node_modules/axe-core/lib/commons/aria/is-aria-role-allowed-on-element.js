import { getNodeFromTree } from '../../core/utils';
import AbstractVirtuaNode from '../../core/base/virtual-node/abstract-virtual-node';
import getImplicitRole from './implicit-role';
import getElementSpec from '../standards/get-element-spec';

/**
 * @description validate if a given role is an allowed ARIA role for the supplied node
 * @method isAriaRoleAllowedOnElement
 * @param {HTMLElement} node the node to verify
 * @param {String} role aria role to check
 * @return {Boolean} retruns true/false
 */
function isAriaRoleAllowedOnElement(node, role) {
  const vNode =
    node instanceof AbstractVirtuaNode ? node : getNodeFromTree(node);
  const implicitRole = getImplicitRole(vNode);

  // always allow the explicit role to match the implicit role
  if (role === implicitRole) {
    return true;
  }

  const spec = getElementSpec(vNode);

  if (Array.isArray(spec.allowedRoles)) {
    return spec.allowedRoles.includes(role);
  }

  return !!spec.allowedRoles;
}

export default isAriaRoleAllowedOnElement;
