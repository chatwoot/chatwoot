import { isDataTable } from '../commons/table';
import { isFocusable } from '../commons/dom';

function dataTableMatches(node) {
  return !isDataTable(node) && !isFocusable(node);
}

export default dataTableMatches;
