import { getRole } from '../../commons/aria';
import { sanitize, labelText, accessibleTextVirtual } from '../../commons/text';

/**
 * Check that an elements explicit label matches its accessible name.
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
 *       <td><code>String</code></td>
 *       <td>The elements explicit role</td>
 *     </tr>
 *   </tbody>
 * </table>
 *
 * @memberof checks
 * @return {Mixed} False if the element does not have an explicit label and accessible name or if there is no mismatch between them. Undefined if the element has an explicit label but no accessible name or if the accessible name does not include the label text.
 */
function noImplicitExplicitLabelEvaluate(node, options, virtualNode) {
  const role = getRole(virtualNode, { noImplicit: true });
  this.data(role);

  let label;
  let accText;
  try {
    label = sanitize(labelText(virtualNode)).toLowerCase();
    accText = sanitize(accessibleTextVirtual(virtualNode)).toLowerCase();
  } catch (e) {
    return undefined;
  }

  if (!accText && !label) {
    return false;
  }

  if (!accText && label) {
    return undefined;
  }

  if (!accText.includes(label)) {
    return undefined;
  }

  return false;
}

export default noImplicitExplicitLabelEvaluate;
