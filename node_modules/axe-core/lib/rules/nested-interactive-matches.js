import { getRole } from '../commons/aria';
import standards from '../standards';

function nestedInteractiveMatches(node, virtualNode) {
  const role = getRole(virtualNode);
  if (!role) {
    return false;
  }

  return !!standards.ariaRoles[role].childrenPresentational;
}

export default nestedInteractiveMatches;
