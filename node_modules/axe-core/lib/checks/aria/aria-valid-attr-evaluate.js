import { validateAttr } from '../../commons/aria';
import { getNodeAttributes } from '../../core/utils';

/**
 * Check that each `aria-` attribute on an element is a valid ARIA attribute.
 *
 * Valid ARIA attributes are listed in the `ariaAttrs` standards object.
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
 *       <td>List of all invalid attributes</td>
 *     </tr>
 *   </tbody>
 * </table>
 *
 * @memberof checks
 * @return {Boolean} True if all `aria-` attributes are valid. False otherwise.
 */
function ariaValidAttrEvaluate(node, options) {
  options = Array.isArray(options.value) ? options.value : [];

  var invalid = [],
    aria = /^aria-/;

  var attr,
    attrs = getNodeAttributes(node);

  for (var i = 0, l = attrs.length; i < l; i++) {
    attr = attrs[i].name;
    if (
      options.indexOf(attr) === -1 &&
      aria.test(attr) &&
      !validateAttr(attr)
    ) {
      invalid.push(attr);
    }
  }

  if (invalid.length) {
    this.data(invalid);
    return false;
  }

  return true;
}

export default ariaValidAttrEvaluate;
