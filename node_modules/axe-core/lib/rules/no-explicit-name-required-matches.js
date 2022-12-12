import { isFocusable } from '../commons/dom';
import { getExplicitRole } from '../commons/aria';
import ariaRoles from '../standards/aria-roles';

/**
 * Filter out elements with an explicit role that does not require an accessible name and is not focusable
 */
function noExplicitNameRequired(node, virtualNode) {
  const role = getExplicitRole(virtualNode);
  if (!role || ['none', 'presentation'].includes(role)) {
    return true;
  }

  const { accessibleNameRequired } = ariaRoles[role] || {};
  if (accessibleNameRequired || isFocusable(virtualNode)) {
    return true;
  }

  return false;
}

export default noExplicitNameRequired;
