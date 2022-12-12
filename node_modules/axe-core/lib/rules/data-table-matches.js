import { isDataTable } from '../commons/table';

function dataTableMatches(node) {
  return isDataTable(node);
}

export default dataTableMatches;
