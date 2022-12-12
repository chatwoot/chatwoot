import * as tableUtils from '../../commons/table';
import { hasContent } from '../../commons/dom';
import { label } from '../../commons/aria';

function tdHasHeaderEvaluate(node) {
  const badCells = [];
  const cells = tableUtils.getAllCells(node);
  const tableGrid = tableUtils.toGrid(node);

  cells.forEach(cell => {
    // For each non-empty data cell that doesn't have an aria label
    if (hasContent(cell) && tableUtils.isDataCell(cell) && !label(cell)) {
      // Check if it has any headers
      const hasHeaders = tableUtils.getHeaders(cell, tableGrid).some(header => {
        return header !== null && !!hasContent(header);
      });

      // If no headers, put it on the naughty list
      if (!hasHeaders) {
        badCells.push(cell);
      }
    }
  });

  if (badCells.length) {
    this.relatedNodes(badCells);
    return false;
  }

  return true;
}

export default tdHasHeaderEvaluate;
