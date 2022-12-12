import { validateAttrValue } from '../../commons/aria';
import { getNodeAttributes } from '../../core/utils';

/**
 * Check that each ARIA attribute on an element has a valid value.
 *
 * Valid ARIA attribute values are taken from the `ariaAttrs` standards object from an attributes `type` property.
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
 *       <td>Object with Strings `messageKey` and `needsReview` if `aria-current` or `aria-describedby` are invalid. Otherwise a list of all invalid ARIA attributes and their value</td>
 *     </tr>
 *   </tbody>
 * </table>
 *
 * @memberof checks
 * @return {Mixed} True if all ARIA attributes have a valid value. Undefined for invalid `aria-current` or `aria-describedby` values. False otherwise.
 */
function ariaValidAttrValueEvaluate(node, options) {
  options = Array.isArray(options.value) ? options.value : [];

  let needsReview = '';
  let messageKey = '';
  const invalid = [];
  const aria = /^aria-/;
  const attrs = getNodeAttributes(node);

  const skipAttrs = ['aria-errormessage'];

  const preChecks = {
    // aria-controls should only check if element exists if the element
    // doesn't have aria-expanded=false or aria-selected=false (tabs)
    // @see https://github.com/dequelabs/axe-core/issues/1463
    'aria-controls': () => {
      return (
        node.getAttribute('aria-expanded') !== 'false' &&
        node.getAttribute('aria-selected') !== 'false'
      );
    },
    // aria-current should mark as needs review if any value is used that is
    // not one of the valid values (since any value is treated as "true")
    'aria-current': () => {
      if (!validateAttrValue(node, 'aria-current')) {
        needsReview = `aria-current="${node.getAttribute('aria-current')}"`;
        messageKey = 'ariaCurrent';
      }

      return;
    },
    // aria-owns should only check if element exists if the element
    // doesn't have aria-expanded=false (combobox)
    // @see https://github.com/dequelabs/axe-core/issues/1524
    'aria-owns': () => {
      return node.getAttribute('aria-expanded') !== 'false';
    },
    // aria-describedby should not mark missing element as violation but
    // instead as needs review
    // @see https://github.com/dequelabs/axe-core/issues/1151
    'aria-describedby': () => {
      if (!validateAttrValue(node, 'aria-describedby')) {
        needsReview = `aria-describedby="${node.getAttribute(
          'aria-describedby'
        )}"`;
        messageKey = 'noId';
      }

      return;
    },
    // aria-labelledby should not mark missing element as violation but
    // instead as needs review
    // @see https://github.com/dequelabs/axe-core/issues/2621
    'aria-labelledby': () => {
      if (!validateAttrValue(node, 'aria-labelledby')) {
        needsReview = `aria-labelledby="${node.getAttribute(
          'aria-labelledby'
        )}"`;
        messageKey = 'noId';
      }
    }
  };

  for (let i = 0, l = attrs.length; i < l; i++) {
    const attr = attrs[i];
    const attrName = attr.name;
    // skip any attributes handled elsewhere
    if (
      !skipAttrs.includes(attrName) &&
      options.indexOf(attrName) === -1 &&
      aria.test(attrName) &&
      (preChecks[attrName] ? preChecks[attrName]() : true) &&
      !validateAttrValue(node, attrName)
    ) {
      invalid.push(`${attrName}="${attr.nodeValue}"`);
    }
  }

  if (needsReview) {
    this.data({
      messageKey,
      needsReview
    });
    return undefined;
  }

  if (invalid.length) {
    this.data(invalid);
    return false;
  }

  return true;
}

export default ariaValidAttrValueEvaluate;
