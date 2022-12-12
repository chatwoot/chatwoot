import { getRole } from '../../commons/aria';
import { sanitize, subtreeText } from '../../commons/text';
import standards from '../../standards';

/**
 * Check that an element does not use any prohibited ARIA attributes.
 *
 * Prohibited attributes are taken from the `ariaAttrs` standards object from the attributes `prohibitedAttrs` property.
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
 *       <td>List of all prohibited attributes</td>
 *     </tr>
 *   </tbody>
 * </table>
 *
 * @memberof checks
 * @return {Boolean} True if the element uses any prohibited ARIA attributes. False otherwise.
 */
function ariaProhibitedAttrEvaluate(node, options, virtualNode) {
  const prohibited = [];

  const role = getRole(virtualNode);
  const attrs = virtualNode.attrNames;
  const prohibitedAttrs = role
    ? standards.ariaRoles[role].prohibitedAttrs
    : ['aria-label', 'aria-labelledby'];

  if (!prohibitedAttrs) {
    return false;
  }

  for (let i = 0; i < attrs.length; i++) {
    const attrName = attrs[i];
    const attrValue = sanitize(virtualNode.attr(attrName));
    if (prohibitedAttrs.includes(attrName) && attrValue !== '') {
      prohibited.push(attrName);
    }
  }

  if (prohibited.length) {
    this.data(prohibited);

    // aria-label and aria-labelledy are not allowed on elements
    // without roles, but if the element has text content then
    // we will return undefined as a screen reader will read
    // the text content
    if (!role && sanitize(subtreeText(virtualNode)) !== '') {
      return undefined;
    }

    return true;
  }

  return false;
}

export default ariaProhibitedAttrEvaluate;
