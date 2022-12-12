import standards from '../../standards';
import { getRootNode } from '../../commons/dom';
import { tokenList } from '../../core/utils';

/**
 * Check if `aria-errormessage` references an element that also uses a technique to announce the message (aria-live, aria-describedby, etc.).
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
 *       <td><code>Mixed</code></td>
 *       <td>The value of the `aria-errormessage` attribute</td>
 *     </tr>
 *   </tbody>
 * </table>
 *
 * @memberof checks
 * @return {Mixed} True if aria-errormessage references an existing element that uses a supported technique. Undefined if it does not reference an existing element. False otherwise.
 */
function ariaErrormessageEvaluate(node, options) {
  options = Array.isArray(options) ? options : [];

  const attr = node.getAttribute('aria-errormessage');
  const hasAttr = node.hasAttribute('aria-errormessage');
  const invaid = node.getAttribute('aria-invalid');
  const hasInvallid = node.hasAttribute('aria-invalid');

  // pass if aria-invalid is not set or set to false as we don't
  // need to check the referenced node since it is not applicable
  if (!hasInvallid || invaid === 'false') {
    return true;
  }

  const doc = getRootNode(node);

  function validateAttrValue(attr) {
    if (attr.trim() === '') {
      return standards.ariaAttrs['aria-errormessage'].allowEmpty;
    }
    const idref = attr && doc.getElementById(attr);
    if (idref) {
      return (
        idref.getAttribute('role') === 'alert' ||
        idref.getAttribute('aria-live') === 'assertive' ||
        idref.getAttribute('aria-live') === 'polite' ||
        tokenList(node.getAttribute('aria-describedby')).indexOf(attr) > -1
      );
    }
    return;
  }

  // limit results to elements that actually have this attribute
  if (options.indexOf(attr) === -1 && hasAttr) {
    this.data(tokenList(attr));
    return validateAttrValue(attr);
  }

  return true;
}

export default ariaErrormessageEvaluate;
