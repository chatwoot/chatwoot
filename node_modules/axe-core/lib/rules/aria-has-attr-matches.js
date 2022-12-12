import { getNodeAttributes } from '../core/utils';

function ariaHasAttrMatches(node) {
  var aria = /^aria-/;
  if (node.hasAttributes()) {
    var attrs = getNodeAttributes(node);
    for (var i = 0, l = attrs.length; i < l; i++) {
      if (aria.test(attrs[i].name)) {
        return true;
      }
    }
  }

  return false;
}

export default ariaHasAttrMatches;
