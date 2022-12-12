import getRootNode from './get-root-node';
import { tokenList } from '../../core/utils';

/**
 * Get elements referenced via a space-separated token attribute;
 * it will insert `null` for any Element that is not found
 * @method idrefs
 * @memberof axe.commons.dom
 * @instance
 * @param  {HTMLElement} node
 * @param  {String} attr The name of attribute
 * @return {Array|null} Array of elements (or `null` if not found)
 *
 * NOTE: When in a shadow DOM environment: ID refs (even for slotted content)
 * refer to the document in which the element is considered to be in the
 * "light DOM". Therefore, we use getElementById on the root node and not QSA
 * on the flattened tree to dereference idrefs.
 *
 */
function idrefs(node, attr) {
  node = node.actualNode || node;

  try {
    const doc = getRootNode(node);
    const result = [];
    let attrValue = node.getAttribute(attr);

    if (attrValue) {
      attrValue = tokenList(attrValue);
      for (let index = 0; index < attrValue.length; index++) {
        result.push(doc.getElementById(attrValue[index]));
      }
    }

    return result;
  } catch (e) {
    throw new TypeError('Cannot resolve id references for non-DOM nodes');
  }
}

export default idrefs;
