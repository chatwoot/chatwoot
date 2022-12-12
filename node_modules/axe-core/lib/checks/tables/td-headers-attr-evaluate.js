import { tokenList } from '../../core/utils';

function tdHeadersAttrEvaluate(node) {
  const cells = [];
  const reviewCells = [];
  const badCells = [];

  for (let rowIndex = 0; rowIndex < node.rows.length; rowIndex++) {
    const row = node.rows[rowIndex];

    for (let cellIndex = 0; cellIndex < row.cells.length; cellIndex++) {
      cells.push(row.cells[cellIndex]);
    }
  }

  const ids = cells.reduce((ids, cell) => {
    if (cell.getAttribute('id')) {
      ids.push(cell.getAttribute('id'));
    }
    return ids;
  }, []);

  cells.forEach(cell => {
    let isSelf = false;
    let notOfTable = false;

    if (!cell.hasAttribute('headers')) {
      return;
    }

    const headersAttr = cell.getAttribute('headers').trim();
    if (!headersAttr) {
      return reviewCells.push(cell);
    }

    // Get a list all the values of the headers attribute
    const headers = tokenList(headersAttr);

    if (headers.length !== 0) {
      // Check if the cell's id is in this list
      if (cell.getAttribute('id')) {
        isSelf = headers.indexOf(cell.getAttribute('id').trim()) !== -1;
      }

      // Check if the headers are of cells inside the table
      notOfTable = headers.some(header => !ids.includes(header));

      if (isSelf || notOfTable) {
        badCells.push(cell);
      }
    }
  });

  if (badCells.length > 0) {
    this.relatedNodes(badCells);
    return false;
  }

  if (reviewCells.length) {
    this.relatedNodes(reviewCells);
    return undefined;
  }

  return true;
}

export default tdHeadersAttrEvaluate;
