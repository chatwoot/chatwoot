import isColumnHeader from './is-column-header';
import isRowHeader from './is-row-header';
import { escapeSelector } from '../../core/utils';

/**
 * Determine if a `HTMLTableCellElement` is a header
 * @method isHeader
 * @memberof axe.commons.table
 * @instance
 * @param  {HTMLTableCellElement} cell The table cell to test
 * @return {Boolean}
 */
function isHeader(cell) {
  if (isColumnHeader(cell) || isRowHeader(cell)) {
    return true;
  }

  if (cell.getAttribute('id')) {
    const id = escapeSelector(cell.getAttribute('id'));
    return !!document.querySelector(`[headers~="${id}"]`);
  }

  return false;
}

export default isHeader;
