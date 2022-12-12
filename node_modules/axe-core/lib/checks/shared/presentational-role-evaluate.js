import { getExplicitRole, getRole } from '../../commons/aria';
import { getGlobalAriaAttrs } from '../../commons/standards';
import { isFocusable } from '../../commons/dom';

function presentationalRoleEvaluate(node, options, virtualNode) {
  const role = getRole(virtualNode);
  const explicitRole = getExplicitRole(virtualNode);

  if (['presentation', 'none'].includes(role)) {
    this.data({ role });
    return true;
  }

  // if the user didn't intended to make this presentational we fail
  if (!['presentation', 'none'].includes(explicitRole)) {
    return false;
  }

  // user intended to make this presentational so inform them of
  // problems caused by role conflict resolution
  const hasGlobalAria = getGlobalAriaAttrs().some(attr =>
    virtualNode.hasAttr(attr)
  );
  const focusable = isFocusable(virtualNode);
  let messageKey;

  if (hasGlobalAria && !focusable) {
    messageKey = 'globalAria';
  } else if (!hasGlobalAria && focusable) {
    messageKey = 'focusable';
  } else {
    messageKey = 'both';
  }

  this.data({
    messageKey,
    role
  });
  return false;
}

export default presentationalRoleEvaluate;
