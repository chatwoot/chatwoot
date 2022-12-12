import { labelVirtual, titleText } from '../../commons/text';

function titleOnlyEvaluate(node, options, virtualNode) {
  const labelText = labelVirtual(virtualNode);
  const title = titleText(virtualNode);
  const ariaDescribedBy = virtualNode.attr('aria-describedby');

  return !labelText && !!(title || ariaDescribedBy);
}

export default titleOnlyEvaluate;
