import getRole from './get-role';
import standards from '../../standards';
import { getNodeFromTree } from '../../core/utils';
import AbstractVirtuaNode from '../../core/base/virtual-node/abstract-virtual-node';

/**
 * Check if an element is named from contents
 *
 * @param {Node|VirtualNode} element
 * @param {Object} options
 * @property {Bool} strict Whether or not to follow the spects strictly
 * @return {Bool}
 */
function namedFromContents(vNode, { strict } = {}) {
  vNode = vNode instanceof AbstractVirtuaNode ? vNode : getNodeFromTree(vNode);
  if (vNode.props.nodeType !== 1) {
    return false;
  }

  const role = getRole(vNode);
  const roleDef = standards.ariaRoles[role];

  if (roleDef && roleDef.nameFromContent) {
    return true;
  }

  /**
   * Note: Strictly speaking if the role is null, presentation, or none, the element
   * isn't named from contents. Axe-core often needs to know if an element
   * has content anyway, so we're allowing it here.
   * Use { strict: true } to disable this behavior.
   */
  if (strict) {
    return false;
  }
  return !roleDef || ['presentation', 'none'].includes(role);
}

export default namedFromContents;
