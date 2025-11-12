# ProseMirror table module

This module defines a schema extension to support tables with
rowspan/colspan support, a custom selection class for cell selections
in such a table, a plugin to manage such selections and enforce
invariants on such tables, and a number of commands to work with
tables.

The top-level directory contains a `demo.js` and `index.html`, which
can be built with `pnpm run build_demo` to show a simple demo of how the
module can be used.

## [Live Demo](https://prosemirror-tables.netlify.app/)

## Documentation

The module's main file exports everything you need to work with it.
The first thing you'll probably want to do is create a table-enabled
schema. That's what `tableNodes` is for:

 * **`tableNodes`**`(options: Object) → Object`\
   This function creates a set of [node
   specs](http://prosemirror.net/docs/ref/#model.SchemaSpec.nodes) for
   `table`, `table_row`, and `table_cell` nodes types as used by this
   module. The result can then be added to the set of nodes when
   creating a a schema.

    * **`options`**`: Object`\
      The following options are understood:

       * **`tableGroup`**`: ?string`\
         A group name (something like `"block"`) to add to the table
         node type.

       * **`cellContent`**`: string`\
         The content expression for table cells.

       * **`cellAttributes`**`: ?Object`\
         Additional attributes to add to cells. Maps attribute names to
         objects with the following properties:

          * **`default`**`: any`\
            The attribute's default value.

          * **`getFromDOM`**`: ?fn(dom.Node) → any`\
            A function to read the attribute's value from a DOM node.

          * **`setDOMAttr`**`: ?fn(value: any, attrs: Object)`\
            A function to add the attribute's value to an attribute
            object that's used to render the cell's DOM.


 * **`tableEditing`**`() → Plugin`\
   Creates a [plugin](http://prosemirror.net/docs/ref/#state.Plugin)
   that, when added to an editor, enables cell-selection, handles
   cell-based copy/paste, and makes sure tables stay well-formed (each
   row has the same width, and cells don't overlap).

   You should probably put this plugin near the end of your array of
   plugins, since it handles mouse and arrow key events in tables
   rather broadly, and other plugins, like the gap cursor or the
   column-width dragging plugin, might want to get a turn first to
   perform more specific behavior.


### class CellSelection extends Selection

A [`Selection`](http://prosemirror.net/docs/ref/#state.Selection)
subclass that represents a cell selection spanning part of a table.
With the plugin enabled, these will be created when the user
selects across cells, and will be drawn by giving selected cells a
`selectedCell` CSS class.

 * `new `**`CellSelection`**`($anchorCell: ResolvedPos, $headCell: ?ResolvedPos = $anchorCell)`\
   A table selection is identified by its anchor and head cells. The
   positions given to this constructor should point _before_ two
   cells in the same table. They may be the same, to select a single
   cell.

 * **`$anchorCell`**`: ResolvedPos`\
   A resolved position pointing _in front of_ the anchor cell (the one
   that doesn't move when extending the selection).

 * **`$headCell`**`: ResolvedPos`\
   A resolved position pointing in front of the head cell (the one
   moves when extending the selection).

 * **`content`**`() → Slice`\
   Returns a rectangular slice of table rows containing the selected
   cells.

 * **`isColSelection`**`() → bool`\
   True if this selection goes all the way from the top to the
   bottom of the table.

 * **`isRowSelection`**`() → bool`\
   True if this selection goes all the way from the left to the
   right of the table.

 * `static `**`colSelection`**`($anchorCell: ResolvedPos, $headCell: ?ResolvedPos = $anchorCell) → CellSelection`\
   Returns the smallest column selection that covers the given anchor
   and head cell.

 * `static `**`rowSelection`**`($anchorCell: ResolvedPos, $headCell: ?ResolvedPos = $anchorCell) → CellSelection`\
   Returns the smallest row selection that covers the given anchor
   and head cell.

 * `static `**`create`**`(doc: Node, anchorCell: number, headCell: ?number = anchorCell) → CellSelection`


### Commands

The following commands can be used to make table-editing functionality
available to users.

 * **`addColumnBefore`**`(state: EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Command to add a column before the column with the selection.


 * **`addColumnAfter`**`(state: EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Command to add a column after the column with the selection.


 * **`deleteColumn`**`(state: EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Command function that removes the selected columns from a table.


 * **`addRowBefore`**`(state: EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Add a table row before the selection.


 * **`addRowAfter`**`(state: EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Add a table row after the selection.


 * **`deleteRow`**`(state: EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Remove the selected rows from a table.


 * **`mergeCells`**`(state: EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Merge the selected cells into a single cell. Only available when
   the selected cells' outline forms a rectangle.


 * **`splitCell`**`(state: EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Split a selected cell, whose rowpan or colspan is greater than one,
   into smaller cells. Use the first cell type for the new cells.


 * **`splitCellWithType`**`(getType: fn({row: number, col: number, node: Node}) → NodeType) → fn(EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Split a selected cell, whose rowpan or colspan is greater than one,
   into smaller cells with the cell type (th, td) returned by getType function.


 * **`setCellAttr`**`(name: string, value: any) → fn(EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Returns a command that sets the given attribute to the given value,
   and is only available when the currently selected cell doesn't
   already have that attribute set to that value.


 * **`toggleHeaderRow`**`(EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Toggles whether the selected row contains header cells.


 * **`toggleHeaderColumn`**`(EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Toggles whether the selected column contains header cells.


 * **`toggleHeaderCell`**`(EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Toggles whether the selected cells are header cells.


 * **`toggleHeader`**`(type: string, options: ?{useDeprecatedLogic: bool}) → fn(EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Toggles between row/column header and normal cells (Only applies to first row/column).
   For deprecated behavior pass `useDeprecatedLogic` in options with true.


 * **`goToNextCell`**`(direction: number) → fn(EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Returns a command for selecting the next (direction=1) or previous
   (direction=-1) cell in a table.


 * **`deleteTable`**`(state: EditorState, dispatch: ?fn(tr: Transaction)) → bool`\
   Deletes the table around the selection, if any.


### Utilities

 * **`fixTables`**`(state: EditorState, oldState: ?EditorState) → ?Transaction`\
   Inspect all tables in the given state's document and return a
   transaction that fixes them, if necessary. If `oldState` was
   provided, that is assumed to hold a previous, known-good state,
   which will be used to avoid re-scanning unchanged parts of the
   document.


### class TableMap

A table map describes the structore of a given table. To avoid
recomputing them all the time, they are cached per table node. To
be able to do that, positions saved in the map are relative to the
start of the table, rather than the start of the document.

 * **`width`**`: number`\
   The width of the table

 * **`height`**`: number`\
   The table's height

 * **`map`**`: [number]`\
   A width * height array with the start position of
   the cell covering that part of the table in each slot

 * **`findCell`**`(pos: number) → Rect`\
   Find the dimensions of the cell at the given position.

 * **`colCount`**`(pos: number) → number`\
   Find the left side of the cell at the given position.

 * **`nextCell`**`(pos: number, axis: string, dir: number) → ?number`\
   Find the next cell in the given direction, starting from the cell
   at `pos`, if any.

 * **`rectBetween`**`(a: number, b: number) → Rect`\
   Get the rectangle spanning the two given cells.

 * **`cellsInRect`**`(rect: Rect) → [number]`\
   Return the position of all cells that have the top left corner in
   the given rectangle.

 * **`positionAt`**`(row: number, col: number, table: Node) → number`\
   Return the position at which the cell at the given row and column
   starts, or would start, if a cell started there.

 * `static `**`get`**`(table: Node) → TableMap`\
   Find the table map for the given table node.


