import { requiredContext, getExplicitRole } from '../commons/aria';

function ariaRequiredParentMatches(node, virtualNode) {
  const role = getExplicitRole(virtualNode);
  return !!requiredContext(role);
}

export default ariaRequiredParentMatches;
