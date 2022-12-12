import { getComposedParent } from '../../commons/dom';
import { getExplicitRole } from '../../commons/aria';

function dlitemEvaluate(node) {
  let parent = getComposedParent(node);
  let parentTagName = parent.nodeName.toUpperCase();
  let parentRole = getExplicitRole(parent);

  if (
    parentTagName === 'DIV' &&
    ['presentation', 'none', null].includes(parentRole)
  ) {
    parent = getComposedParent(parent);
    parentTagName = parent.nodeName.toUpperCase();
    parentRole = getExplicitRole(parent);
  }

  // Unlike with UL|OL+LI, DT|DD must be in a DL
  if (parentTagName !== 'DL') {
    return false;
  }

  if (!parentRole || ['presentation', 'none', 'list'].includes(parentRole)) {
    return true;
  }

  return false;
}

export default dlitemEvaluate;
