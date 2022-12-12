import idrefs from '../dom/idrefs';
import visibleVirtual from '../text/visible-virtual';
import sanitize from '../text/sanitize';
import { getNodeFromTree } from '../../core/utils';

/**
 * Gets the accessible ARIA label text of a given element
 * @see http://www.w3.org/WAI/PF/aria/roles#namecalculation
 * @method labelVirtual
 * @memberof axe.commons.aria
 * @instance
 * @param  {VirtualNode} virtualNode The virtualNode to test
 * @return {Mixed}  String of visible text, or `null` if no label is found
 */
function labelVirtual(virtualNode) {
  let ref, candidate;

  if (virtualNode.attr('aria-labelledby')) {
    // aria-labelledby
    ref = idrefs(virtualNode.actualNode, 'aria-labelledby');
    candidate = ref
      .map(thing => {
        const vNode = getNodeFromTree(thing);
        return vNode ? visibleVirtual(vNode, true) : '';
      })
      .join(' ')
      .trim();

    if (candidate) {
      return candidate;
    }
  }

  // aria-label
  candidate = virtualNode.attr('aria-label');
  if (candidate) {
    candidate = sanitize(candidate);
    if (candidate) {
      return candidate;
    }
  }

  return null;
}

export default labelVirtual;
