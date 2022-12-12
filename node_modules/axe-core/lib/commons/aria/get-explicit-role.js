import isValidRole from './is-valid-role';
import { getNodeFromTree, tokenList } from '../../core/utils';
import AbstractVirtuaNode from '../../core/base/virtual-node/abstract-virtual-node';

function getExplicitRole(vNode, { fallback, abstracts, dpub } = {}) {
  vNode = vNode instanceof AbstractVirtuaNode ? vNode : getNodeFromTree(vNode);

  if (vNode.props.nodeType !== 1) {
    return null;
  }

  const roleAttr = (vNode.attr('role') || '').trim().toLowerCase();
  const roleList = fallback ? tokenList(roleAttr) : [roleAttr];

  // Get the first valid role:
  const firstValidRole = roleList.find(role => {
    if (!dpub && role.substr(0, 4) === 'doc-') {
      return false;
    }
    return isValidRole(role, { allowAbstract: abstracts });
  });

  return firstValidRole || null;
}

export default getExplicitRole;
