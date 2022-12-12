import ariaLabelVirtual from '../aria/label-virtual';
import visible from './visible';
import visibleVirtual from './visible-virtual';
import getRootNode from '../dom/get-root-node';
import { closest, escapeSelector } from '../../core/utils';

/**
 * Gets the visible text of a label for a given input
 * @see http://www.w3.org/WAI/PF/aria/roles#namecalculation
 * @method labelVirtual
 * @memberof axe.commons.text
 * @instance
 * @param  {VirtualNode} node The virtual node mapping to the input to test
 * @return {Mixed} String of visible text, or `null` if no label is found
 */
function labelVirtual(virtualNode) {
  var ref, candidate, doc;

  candidate = ariaLabelVirtual(virtualNode);
  if (candidate) {
    return candidate;
  }

  // explicit label
  if (virtualNode.attr('id')) {
    if (!virtualNode.actualNode) {
      throw new TypeError(
        'Cannot resolve explicit label reference for non-DOM nodes'
      );
    }

    const id = escapeSelector(virtualNode.attr('id'));
    doc = getRootNode(virtualNode.actualNode);
    ref = doc.querySelector('label[for="' + id + '"]');
    candidate = ref && visible(ref, true);
    if (candidate) {
      return candidate;
    }
  }

  ref = closest(virtualNode, 'label');
  candidate = ref && visibleVirtual(ref, true);
  if (candidate) {
    return candidate;
  }

  return null;
}

export default labelVirtual;
