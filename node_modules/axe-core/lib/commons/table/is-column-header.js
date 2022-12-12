import getScope from './get-scope';

/**
 * Determine if a `HTMLTableCellElement` is a column header
 * @method isColumnHeader
 * @memberof axe.commons.table
 * @instance
 * @param  {HTMLTableCellElement} element The table cell to test
 * @return {Boolean}
 */
function isColumnHeader(element) {
  return ['col', 'auto'].indexOf(getScope(element)) !== -1;
}

export default isColumnHeader;
