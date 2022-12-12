import { closest } from '../core/utils';

function svgNamespaceMatches(node, virtualNode) {
  try {
    const nodeName = virtualNode.props.nodeName;

    if (nodeName === 'svg') {
      return true;
    }

    // element is svg namespace if its parent is an svg element
    return !!closest(virtualNode, 'svg');
  } catch (e) {
    return false;
  }
}

export default svgNamespaceMatches;
