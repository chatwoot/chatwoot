import * as tableUtils from '../../commons/table';
import { sanitize } from '../../commons/text';

function thHasDataCellsEvaluate(node) {
  const cells = tableUtils.getAllCells(node);
  const checkResult = this;

  // Get a list of all headers reffed to in this rule
  let reffedHeaders = [];
  cells.forEach(cell => {
    const headers = cell.getAttribute('headers');
    if (headers) {
      reffedHeaders = reffedHeaders.concat(headers.split(/\s+/));
    }

    const ariaLabel = cell.getAttribute('aria-labelledby');
    if (ariaLabel) {
      reffedHeaders = reffedHeaders.concat(ariaLabel.split(/\s+/));
    }
  });

  // Get all the headers
  const headers = cells.filter(cell => {
    if (sanitize(cell.textContent) === '') {
      return false;
    }
    return (
      cell.nodeName.toUpperCase() === 'TH' ||
      ['rowheader', 'columnheader'].indexOf(cell.getAttribute('role')) !== -1
    );
  });

  const tableGrid = tableUtils.toGrid(node);

  let out = true;
  headers.forEach(header => {
    if (
      header.getAttribute('id') &&
      reffedHeaders.includes(header.getAttribute('id'))
    ) {
      return;
    }

    const pos = tableUtils.getCellPosition(header, tableGrid);

    // ensure column header has at least 1 non-header cell and that the cell is
    // not pointing to a different header
    let hasCell = false;
    if (tableUtils.isColumnHeader(header)) {
      hasCell = tableUtils
        .traverse('down', pos, tableGrid)
        .find(
          cell =>
            !tableUtils.isColumnHeader(cell) &&
            tableUtils.getHeaders(cell, tableGrid).includes(header)
        );
    }

    // ensure row header has at least 1 non-header cell and that the cell is not
    // pointing to a different header
    if (!hasCell && tableUtils.isRowHeader(header)) {
      hasCell = tableUtils
        .traverse('right', pos, tableGrid)
        .find(
          cell =>
            !tableUtils.isRowHeader(cell) &&
            tableUtils.getHeaders(cell, tableGrid).includes(header)
        );
    }

    // report the node as having failed
    if (!hasCell) {
      checkResult.relatedNodes(header);
    }

    out = out && hasCell;
  });

  return out ? true : undefined;
}

export default thHasDataCellsEvaluate;
