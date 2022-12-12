import { validateAttr } from '../../commons/aria';
import standards from '../../standards';
import matches from '../../commons/matches';

/**
 * Check that an element does not use any unsupported ARIA attributes.
 *
 * Unsupported attributes are taken from the `ariaAttrs` standards object from the attributes `unsupported` property.
 *
 * ##### Data:
 * <table class="props">
 *   <thead>
 *     <tr>
 *       <th>Type</th>
 *       <th>Description</th>
 *     </tr>
 *   </thead>
 *   <tbody>
 *     <tr>
 *       <td><code>String[]</code></td>
 *       <td>List of all unsupported attributes</td>
 *     </tr>
 *   </tbody>
 * </table>
 *
 * @memberof checks
 * @return {Boolean} True if the element does not use any unsupported ARIA attributes. False otherwise.
 */
function ariaUnsupportedAttrEvaluate(node, options, virtualNode) {
  const unsupportedAttrs = virtualNode.attrNames.filter(name => {
    const attribute = standards.ariaAttrs[name];

    if (!validateAttr(name)) {
      return false;
    }

    const { unsupported } = attribute;

    if (typeof unsupported !== 'object') {
      return !!unsupported;
    }

    return !matches(node, unsupported.exceptions);
  });

  if (unsupportedAttrs.length) {
    this.data(unsupportedAttrs);
    return true;
  }
  return false;
}

export default ariaUnsupportedAttrEvaluate;
