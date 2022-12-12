import { getRole } from '../../commons/aria';
import { visibleVirtual, accessibleTextVirtual } from '../../commons/text';
import { closest } from '../../core/utils';

function duplicateImgLabelEvaluate(node, options, virtualNode) {
  if (['none', 'presentation'].includes(getRole(virtualNode))) {
    return false;
  }
  const parentVNode = closest(virtualNode, options.parentSelector);

  if (!parentVNode) {
    return false;
  }

  const visibleText = visibleVirtual(parentVNode, true).toLowerCase();
  if (visibleText === '') {
    return false;
  }

  return visibleText === accessibleTextVirtual(virtualNode).toLowerCase();
}

export default duplicateImgLabelEvaluate;
