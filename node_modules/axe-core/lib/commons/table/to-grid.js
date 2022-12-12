import { memoize } from '../../core/utils';

/**
 * Converts a table to an Array of arrays, normalized for row and column spans
 * @method toGrid
 * @memberof axe.commons.table
 * @instance
 * @param  {HTMLTableElement} node The table to convert
 * @return {Array<HTMLTableCellElement>} Array of HTMLTableCellElements
 */
function toGrid(node) {
  var table = [];
  var rows = node.rows;
  for (var i = 0, rowLength = rows.length; i < rowLength; i++) {
    var cells = rows[i].cells;
    table[i] = table[i] || [];

    var columnIndex = 0;

    for (var j = 0, cellLength = cells.length; j < cellLength; j++) {
      for (var colSpan = 0; colSpan < cells[j].colSpan; colSpan++) {
        // if [the rowSpan] value is set to 0, it extends until the
        // end of the table section
        // @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/td#attr-rowspan

        // ie11 returns 1 as the rowspan value even if it's set to 0
        const rowspanAttr = cells[j].getAttribute('rowspan');
        const rowspanValue =
          parseInt(rowspanAttr) === 0 || cells[j].rowspan === 0
            ? rows.length
            : cells[j].rowSpan;

        for (var rowSpan = 0; rowSpan < rowspanValue; rowSpan++) {
          table[i + rowSpan] = table[i + rowSpan] || [];
          while (table[i + rowSpan][columnIndex]) {
            columnIndex++;
          }
          table[i + rowSpan][columnIndex] = cells[j];
        }
        columnIndex++;
      }
    }
  }

  return table;
}

export default memoize(toGrid);
