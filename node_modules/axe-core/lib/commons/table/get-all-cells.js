/**
 * Returns all cells contained in given HTMLTableElement
 * @method getAllCells
 * @memberof axe.commons.table
 * @instance
 * @param  {HTMLTableElement} tableElm Table Element to get cells from
 * @return {Array<HTMLTableCellElement>}
 */
function getAllCells(tableElm) {
  var rowIndex, cellIndex, rowLength, cellLength;
  var cells = [];
  for (
    rowIndex = 0, rowLength = tableElm.rows.length;
    rowIndex < rowLength;
    rowIndex++
  ) {
    for (
      cellIndex = 0, cellLength = tableElm.rows[rowIndex].cells.length;
      cellIndex < cellLength;
      cellIndex++
    ) {
      cells.push(tableElm.rows[rowIndex].cells[cellIndex]);
    }
  }
  return cells;
}

export default getAllCells;
