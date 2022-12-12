import getScope from './get-scope';

/**
 * Determine if a `HTMLTableCellElement` is a row header
 * @method isRowHeader
 * @memberof axe.commons.table
 * @instance
 * @param  {HTMLTableCellElement} cell The table cell to test
 * @return {Boolean}
 */
function isRowHeader(cell) {
  return ['row', 'auto'].includes(getScope(cell));
}

export default isRowHeader;
