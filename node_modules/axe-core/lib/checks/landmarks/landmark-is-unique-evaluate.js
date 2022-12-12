import { getRole } from '../../commons/aria';
import { accessibleTextVirtual } from '../../commons/text';

function landmarkIsUniqueEvaluate(node, options, virtualNode) {
  var role = getRole(node);
  var accessibleText = accessibleTextVirtual(virtualNode);
  accessibleText = accessibleText ? accessibleText.toLowerCase() : null;
  this.data({ role: role, accessibleText: accessibleText });
  this.relatedNodes([node]);

  return true;
}

export default landmarkIsUniqueEvaluate;
