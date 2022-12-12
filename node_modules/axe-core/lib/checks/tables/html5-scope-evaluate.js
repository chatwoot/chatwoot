import { isHTML5 } from '../../commons/dom';

function html5ScopeEvaluate(node) {
  if (!isHTML5(document)) {
    return true;
  }

  return node.nodeName.toUpperCase() === 'TH';
}

export default html5ScopeEvaluate;
