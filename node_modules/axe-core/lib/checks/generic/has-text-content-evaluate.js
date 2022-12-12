import { sanitize, subtreeText } from '../../commons/text';

function hasTextContentEvaluate(node, options, virtualNode) {
  try {
    return sanitize(subtreeText(virtualNode)) !== '';
  } catch (e) {
    return undefined;
  }
}

export default hasTextContentEvaluate;
