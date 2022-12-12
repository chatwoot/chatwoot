import { toGrid } from '../../commons/table';

function captionFakedEvaluate(node) {
  var table = toGrid(node);
  var firstRow = table[0];

  if (table.length <= 1 || firstRow.length <= 1 || node.rows.length <= 1) {
    return true;
  }

  return firstRow.reduce((out, curr, i) => {
    return out || (curr !== firstRow[i + 1] && firstRow[i + 1] !== undefined);
  }, false);
}

export default captionFakedEvaluate;
