import { tokenList } from '../../core/utils';

/**
 * Check that an element does not use more than one explicit role.
 *
 * @memberof checks
 * @return {Boolean} True if the element uses more than one explicit role. False otherwise.
 */
function fallbackroleEvaluate(node, options, virtualNode) {
  return tokenList(virtualNode.attr('role')).length > 1;
}

export default fallbackroleEvaluate;
