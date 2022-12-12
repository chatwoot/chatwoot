import { isUnsupportedRole, getRole } from '../../commons/aria';

/**
 * Check that an elements semantic role is unsupported.
 *
 * Unsupported roles are taken from the `ariaRoles` standards object from the roles `unsupported` property.
 *
 * @memberof checks
 * @return {Boolean} True if the elements semantic role is unsupported. False otherwise.
 */
function unsupportedroleEvaluate(node, options, virtualNode) {
  return isUnsupportedRole(getRole(virtualNode));
}

export default unsupportedroleEvaluate;
