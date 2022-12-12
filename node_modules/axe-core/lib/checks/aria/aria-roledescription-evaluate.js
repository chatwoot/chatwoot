import { getRole } from '../../commons/aria';

/**
 * Check that `aria-roledescription` is used on a supported semantic role.
 *
 * @memberof checks
 * @param {String[]} options.supportedRoles List of ARIA roles that support the `aria-roledescription` attribute
 * @return {Mixed} True if the semantic role supports `aria-roledescription`. Undefined if the semantic role is `presentation` or `none`. False otherwise.
 */
function ariaRoledescriptionEvaluate(node, options = {}) {
  const role = getRole(node);
  const supportedRoles = options.supportedRoles || [];

  if (supportedRoles.includes(role)) {
    return true;
  }

  if (role && role !== 'presentation' && role !== 'none') {
    return undefined;
  }

  return false;
}

export default ariaRoledescriptionEvaluate;
