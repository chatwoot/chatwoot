import { closest } from '../../core/utils';
import { accessibleTextVirtual } from '../../commons/text';

function implicitEvaluate(node, options, virtualNode) {
  try {
    const label = closest(virtualNode, 'label');
    if (label) {
      return !!accessibleTextVirtual(label, { inControlContext: true });
    }
    return false;
  } catch (e) {
    return undefined;
  }
}

export default implicitEvaluate;
