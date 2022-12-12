import hasContentVirtual from './has-content-virtual';
import { getNodeFromTree } from '../../core/utils';

/**
 * Find virtual node and call hasContentVirtual()
 * IMPORTANT: This method requires the composed tree at axe._tree
 * @see axe.commons.dom.hasContentVirtual
 * @method hasContent
 * @memberof axe.commons.dom
 * @instance
 * @param {DOMNode} elm DOMNode element to check
 * @param {Boolean} noRecursion If true, only the element is checked, otherwise it will search all child nodes
 * @param {Boolean} ignoreAria if true, ignores `aria label` computation for content deduction
 * @return {Boolean}
 */
function hasContent(elm, noRecursion, ignoreAria) {
  elm = getNodeFromTree(elm);
  return hasContentVirtual(elm, noRecursion, ignoreAria);
}

export default hasContent;
