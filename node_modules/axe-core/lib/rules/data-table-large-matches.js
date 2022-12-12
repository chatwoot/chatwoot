import { isDataTable, toArray } from '../commons/table';

function dataTableLargeMatches(node) {
  if (isDataTable(node)) {
    var tableArray = toArray(node);
    return (
      tableArray.length >= 3 &&
      tableArray[0].length >= 3 &&
      tableArray[1].length >= 3 &&
      tableArray[2].length >= 3
    );
  }

  return false;
}

export default dataTableLargeMatches;
