import isValidRole from '../aria/is-valid-role';

/**
 * Determine if a `HTMLTableCellElement` is a data cell
 * @method isDataCell
 * @memberof axe.commons.table
 * @instance
 * @param  {HTMLTableCellElement} node The table cell to test
 * @return {Boolean}
 */
function isDataCell(cell) {
  // @see http://www.whatwg.org/specs/web-apps/current-work/multipage/tables.html#empty-cell
  if (!cell.children.length && !cell.textContent.trim()) {
    return false;
  }
  const role = cell.getAttribute('role');
  if (isValidRole(role)) {
    return ['cell', 'gridcell'].includes(role);
  } else {
    return cell.nodeName.toUpperCase() === 'TD';
  }
}

export default isDataCell;
