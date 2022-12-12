import { accessibleTextVirtual } from '../commons/text';
import { getRole } from '../commons/aria';

function identicalLinksSamePurposeMatches(node, virtualNode) {
  const hasAccName = !!accessibleTextVirtual(virtualNode);
  if (!hasAccName) {
    return false;
  }

  const role = getRole(node);
  if (role && role !== 'link') {
    return false;
  }

  return true;
}

export default identicalLinksSamePurposeMatches;
