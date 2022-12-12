import { requiredAttr, getExplicitRole } from '../../commons/aria';
import { getElementSpec } from '../../commons/standards';
import { uniqueArray } from '../../core/utils';

/**
 * Check that the element has all required attributes for its explicit role.
 *
 * Required ARIA attributes are taken from the `ariaRoles` standards object from the roles `requiredAttrs` property.
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
 *       <td>List of all missing require attributes</td>
 *     </tr>
 *   </tbody>
 * </table>
 *
 * @memberof checks
 * @return {Boolean} True if all required attributes are present. False otherwise.
 */
function ariaRequiredAttrEvaluate(node, options = {}, virtualNode) {
  const missing = [];
  const attrs = virtualNode.attrNames;

  if (attrs.length) {
    const role = getExplicitRole(virtualNode);
    let required = requiredAttr(role);
    const elmSpec = getElementSpec(virtualNode);

    // @deprecated: required attr options to pass more attrs.
    // configure the standards spec instead
    if (Array.isArray(options[role])) {
      required = uniqueArray(options[role], required);
    }
    if (role && required) {
      for (let i = 0, l = required.length; i < l; i++) {
        const attr = required[i];
        if (
          !virtualNode.attr(attr) &&
          !(
            elmSpec.implicitAttrs &&
            typeof elmSpec.implicitAttrs[attr] !== 'undefined'
          )
        ) {
          missing.push(attr);
        }
      }
    }
  }

  if (missing.length) {
    this.data(missing);
    return false;
  }

  return true;
}

export default ariaRequiredAttrEvaluate;
