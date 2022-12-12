import { getRole, implicitRole } from '../../commons/aria';
import { getAriaRolesByType } from '../../commons/standards';
import { getComposedParent } from '../../commons/dom';

function landmarkIsTopLevelEvaluate(node) {
  var landmarks = getAriaRolesByType('landmark');
  var parent = getComposedParent(node);
  var nodeRole = getRole(node);

  this.data({ role: nodeRole });

  while (parent) {
    var role = parent.getAttribute('role');
    if (!role && parent.nodeName.toUpperCase() !== 'FORM') {
      role = implicitRole(parent);
    }
    // allow aside inside main
    // @see https://github.com/dequelabs/axe-core/issues/2651
    if (
      role &&
      landmarks.includes(role) &&
      !(role === 'main' && nodeRole === 'complementary')
    ) {
      return false;
    }
    parent = getComposedParent(parent);
  }
  return true;
}

export default landmarkIsTopLevelEvaluate;
