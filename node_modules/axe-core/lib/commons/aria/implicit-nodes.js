import { clone } from '../../core/utils';
import lookupTable from './lookup-table';

/**
 * Get a list of CSS selectors of nodes that have an implicit role
 * @method implicitNodes
 * @memberof axe.commons.aria
 * @deprecated
 * @instance
 * @param {String} role The role to check
 * @return {Mixed} Either an Array of CSS selectors or `null` if there are none
 */
function implicitNodes(role) {
  let implicit = null;
  const roles = lookupTable.role[role];

  if (roles && roles.implicit) {
    implicit = clone(roles.implicit);
  }
  return implicit;
}

export default implicitNodes;
