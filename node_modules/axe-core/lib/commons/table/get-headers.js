import isRowHeader from './is-row-header';
import isColumnHeader from './is-column-header';
import toGrid from './to-grid';
import getCellPosition from './get-cell-position';
import idrefs from '../dom/idrefs';
import findUp from '../dom/find-up';

/**
 * Loop through the table grid looking for headers and caching the result.
 * @param {String} headerType The type of header to look for ("row" or "col")
 * @param {Object} position The position of the cell to start looking
 * @param {Array} tablegrid A matrix of the table obtained using axe.commons.table.toGrid
 * @return {Array<HTMLTableCellElement>} Array of HTMLTableCellElements that are headers
 */
function traverseForHeaders(headerType, position, tableGrid) {
  const property = headerType === 'row' ? '_rowHeaders' : '_colHeaders';
  const predicate = headerType === 'row' ? isRowHeader : isColumnHeader;
  const startCell = tableGrid[position.y][position.x];

  // adjust position by rowspan and colspan
  // subtract 1 from col/rowspan to make them 0 indexed
  const colspan = startCell.colSpan - 1;

  // ie11 returns 1 as the rowspan value even if it's set to 0
  const rowspanAttr = startCell.getAttribute('rowspan');
  const rowspanValue =
    parseInt(rowspanAttr) === 0 || startCell.rowspan === 0
      ? tableGrid.length
      : startCell.rowSpan;
  const rowspan = rowspanValue - 1;

  const rowStart = position.y + rowspan;
  const colStart = position.x + colspan;

  const rowEnd = headerType === 'row' ? position.y : 0;
  const colEnd = headerType === 'row' ? 0 : position.x;

  let headers;
  const cells = [];
  for (let row = rowStart; row >= rowEnd && !headers; row--) {
    for (let col = colStart; col >= colEnd; col--) {
      const cell = tableGrid[row] ? tableGrid[row][col] : undefined;

      if (!cell) {
        continue;
      }

      // stop traversing once we've found a cache
      const vNode = axe.utils.getNodeFromTree(cell);
      if (vNode[property]) {
        headers = vNode[property];
        break;
      }

      cells.push(cell);
    }
  }

  // need to check that the cells we've traversed are headers
  headers = (headers || []).concat(cells.filter(predicate));

  // cache results
  cells.forEach(tableCell => {
    const vNode = axe.utils.getNodeFromTree(tableCell);
    vNode[property] = headers;
  });

  return headers;
}

/**
 * Get any associated table headers for a `HTMLTableCellElement`
 * @method getHeaders
 * @memberof axe.commons.table
 * @instance
 * @param  {HTMLTableCellElement} cell The cell of which to get headers
 * @param {Array} [tablegrid] A matrix of the table obtained using axe.commons.table.toGrid
 * @return {Array<HTMLTableCellElement>} Array of headers associated to the table cell
 */
function getHeaders(cell, tableGrid) {
  if (cell.getAttribute('headers')) {
    const headers = idrefs(cell, 'headers');

    // testing has shown that if the headers attribute is incorrect the browser
    // will default to the table row/column headers
    if (headers.filter(header => header).length) {
      return headers;
    }
  }
  if (!tableGrid) {
    tableGrid = toGrid(findUp(cell, 'table'));
  }
  const position = getCellPosition(cell, tableGrid);

  // TODO: RTL text
  const rowHeaders = traverseForHeaders('row', position, tableGrid);
  const colHeaders = traverseForHeaders('col', position, tableGrid);

  return [].concat(rowHeaders, colHeaders).reverse();
}

export default getHeaders;
