import { sanitize } from '../../commons/text';
import { arialabelText } from '../../commons/aria';

function ariaLabelEvaluate(node, options, virtualNode) {
  return !!sanitize(arialabelText(virtualNode));
}

export default ariaLabelEvaluate;
