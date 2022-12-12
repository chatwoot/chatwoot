import getRoleType from '../aria/get-role-type';
import isFocusable from '../dom/is-focusable';
import findUp from '../dom/find-up';
import getElementCoordinates from '../dom/get-element-coordinates';
import getViewportSize from '../dom/get-viewport-size';

/**
 * Determines whether a table is a data table
 * @method isDataTable
 * @memberof axe.commons.table
 * @instance
 * @param  {HTMLTableElement} node The table to test
 * @return {Boolean}
 * @see http://asurkov.blogspot.co.uk/2011/10/data-vs-layout-table.html
 */
function isDataTable(node) {
  var role = (node.getAttribute('role') || '').toLowerCase();

  // The element is not focusable and has role=presentation
  if ((role === 'presentation' || role === 'none') && !isFocusable(node)) {
    return false;
  }

  // Table inside editable area is data table always since the table structure is crucial for table editing
  if (
    node.getAttribute('contenteditable') === 'true' ||
    findUp(node, '[contenteditable="true"]')
  ) {
    return true;
  }

  // Table having ARIA table related role is data table
  if (role === 'grid' || role === 'treegrid' || role === 'table') {
    return true;
  }

  // Table having ARIA landmark role is data table
  if (getRoleType(role) === 'landmark') {
    return true;
  }

  // Table having datatable="0" attribute is layout table
  if (node.getAttribute('datatable') === '0') {
    return false;
  }

  // Table having summary attribute is data table
  if (node.getAttribute('summary')) {
    return true;
  }

  // Table having legitimate data table structures is data table
  if (node.tHead || node.tFoot || node.caption) {
    return true;
  }
  // colgroup / col - colgroup is magically generated
  for (
    var childIndex = 0, childLength = node.children.length;
    childIndex < childLength;
    childIndex++
  ) {
    if (node.children[childIndex].nodeName.toUpperCase() === 'COLGROUP') {
      return true;
    }
  }

  var cells = 0;
  var rowLength = node.rows.length;
  var row, cell;
  var hasBorder = false;
  for (var rowIndex = 0; rowIndex < rowLength; rowIndex++) {
    row = node.rows[rowIndex];
    for (
      var cellIndex = 0, cellLength = row.cells.length;
      cellIndex < cellLength;
      cellIndex++
    ) {
      cell = row.cells[cellIndex];
      if (cell.nodeName.toUpperCase() === 'TH') {
        return true;
      }
      if (
        !hasBorder &&
        (cell.offsetWidth !== cell.clientWidth ||
          cell.offsetHeight !== cell.clientHeight)
      ) {
        hasBorder = true;
      }
      if (
        cell.getAttribute('scope') ||
        cell.getAttribute('headers') ||
        cell.getAttribute('abbr')
      ) {
        return true;
      }
      if (
        ['columnheader', 'rowheader'].includes(
          (cell.getAttribute('role') || '').toLowerCase()
        )
      ) {
        return true;
      }
      // abbr element as a single child element of table cell
      if (
        cell.children.length === 1 &&
        cell.children[0].nodeName.toUpperCase() === 'ABBR'
      ) {
        return true;
      }
      cells++;
    }
  }

  // Table having nested table is layout table
  if (node.getElementsByTagName('table').length) {
    return false;
  }

  // Table having only one row or column is layout table (row)
  if (rowLength < 2) {
    return false;
  }

  // Table having only one row or column is layout table (column)
  var sampleRow = node.rows[Math.ceil(rowLength / 2)];
  if (sampleRow.cells.length === 1 && sampleRow.cells[0].colSpan === 1) {
    return false;
  }

  // Table having many columns (>= 5) is data table
  if (sampleRow.cells.length >= 5) {
    return true;
  }

  // Table having borders around cells is data table
  if (hasBorder) {
    return true;
  }

  // Table having differently colored rows is data table
  var bgColor, bgImage;
  for (rowIndex = 0; rowIndex < rowLength; rowIndex++) {
    row = node.rows[rowIndex];
    if (
      bgColor &&
      bgColor !==
        window.getComputedStyle(row).getPropertyValue('background-color')
    ) {
      return true;
    } else {
      bgColor = window
        .getComputedStyle(row)
        .getPropertyValue('background-color');
    }
    if (
      bgImage &&
      bgImage !==
        window.getComputedStyle(row).getPropertyValue('background-image')
    ) {
      return true;
    } else {
      bgImage = window
        .getComputedStyle(row)
        .getPropertyValue('background-image');
    }
  }

  // Table having many rows (>= 20) is data table
  if (rowLength >= 20) {
    return true;
  }

  // Wide table (more than 95% of the document width) is layout table
  if (
    getElementCoordinates(node).width >
    getViewportSize(window).width * 0.95
  ) {
    return false;
  }

  // Table having small amount of cells (<= 10) is layout table
  if (cells < 10) {
    return false;
  }

  // Table containing embed, object, applet of iframe elements (typical advertisements elements) is layout table
  if (node.querySelector('object, embed, iframe, applet')) {
    return false;
  }

  // Otherwise it's data table
  return true;
}

export default isDataTable;
