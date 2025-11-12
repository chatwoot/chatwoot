import { PluginKey, EditorState, Transaction, Selection, Plugin, Command } from 'prosemirror-state';
import { Slice, Node, ResolvedPos, Attrs, NodeType, Fragment, NodeSpec, Schema } from 'prosemirror-model';
import { EditorView, NodeView } from 'prosemirror-view';
import { Mappable } from 'prosemirror-transform';

/**
 * @public
 */
declare const fixTablesKey: PluginKey<{
    fixTables: boolean;
}>;
/**
 * Inspect all tables in the given state's document and return a
 * transaction that fixes them, if necessary. If `oldState` was
 * provided, that is assumed to hold a previous, known-good state,
 * which will be used to avoid re-scanning unchanged parts of the
 * document.
 *
 * @public
 */
declare function fixTables(state: EditorState, oldState?: EditorState): Transaction | undefined;

/**
 * @public
 */
type Direction = -1 | 1;
/**
 * @public
 */
declare function handlePaste(view: EditorView, _: ClipboardEvent, slice: Slice): boolean;

/**
 * @public
 */
type ColWidths = number[];
/**
 * @public
 */
type Problem = {
    type: 'colwidth mismatch';
    pos: number;
    colwidth: ColWidths;
} | {
    type: 'collision';
    pos: number;
    row: number;
    n: number;
} | {
    type: 'missing';
    row: number;
    n: number;
} | {
    type: 'overlong_rowspan';
    pos: number;
    n: number;
};
/**
 * @public
 */
interface Rect {
    left: number;
    top: number;
    right: number;
    bottom: number;
}
/**
 * A table map describes the structure of a given table. To avoid
 * recomputing them all the time, they are cached per table node. To
 * be able to do that, positions saved in the map are relative to the
 * start of the table, rather than the start of the document.
 *
 * @public
 */
declare class TableMap {
    /**
     * The number of columns
     */
    width: number;
    /**
     * The number of rows
     */
    height: number;
    /**
     * A width * height array with the start position of
     * the cell covering that part of the table in each slot
     */
    map: number[];
    /**
     * An optional array of problems (cell overlap or non-rectangular
     * shape) for the table, used by the table normalizer.
     */
    problems: Problem[] | null;
    constructor(
    /**
     * The number of columns
     */
    width: number, 
    /**
     * The number of rows
     */
    height: number, 
    /**
     * A width * height array with the start position of
     * the cell covering that part of the table in each slot
     */
    map: number[], 
    /**
     * An optional array of problems (cell overlap or non-rectangular
     * shape) for the table, used by the table normalizer.
     */
    problems: Problem[] | null);
    findCell(pos: number): Rect;
    colCount(pos: number): number;
    nextCell(pos: number, axis: 'horiz' | 'vert', dir: number): null | number;
    rectBetween(a: number, b: number): Rect;
    cellsInRect(rect: Rect): number[];
    positionAt(row: number, col: number, table: Node): number;
    static get(table: Node): TableMap;
}

/**
 * @public
 */
type MutableAttrs = Record<string, unknown>;
/**
 * @public
 */
interface CellAttrs {
    colspan: number;
    rowspan: number;
    colwidth: number[] | null;
}
/**
 * @public
 */
declare const tableEditingKey: PluginKey<number>;
/**
 * @public
 */
declare function cellAround($pos: ResolvedPos): ResolvedPos | null;
/**
 * @public
 */
declare function isInTable(state: EditorState): boolean;
/**
 * @internal
 */
declare function selectionCell(state: EditorState): ResolvedPos;
/**
 * @public
 */
declare function cellNear($pos: ResolvedPos): ResolvedPos | undefined;
/**
 * @public
 */
declare function pointsAtCell($pos: ResolvedPos): boolean;
/**
 * @public
 */
declare function moveCellForward($pos: ResolvedPos): ResolvedPos;
/**
 * @internal
 */
declare function inSameTable($cellA: ResolvedPos, $cellB: ResolvedPos): boolean;
/**
 * @public
 */
declare function findCell($pos: ResolvedPos): Rect;
/**
 * @public
 */
declare function colCount($pos: ResolvedPos): number;
/**
 * @public
 */
declare function nextCell($pos: ResolvedPos, axis: 'horiz' | 'vert', dir: number): ResolvedPos | null;
/**
 * @public
 */
declare function removeColSpan(attrs: CellAttrs, pos: number, n?: number): CellAttrs;
/**
 * @public
 */
declare function addColSpan(attrs: CellAttrs, pos: number, n?: number): Attrs;
/**
 * @public
 */
declare function columnIsHeader(map: TableMap, table: Node, col: number): boolean;

/**
 * @public
 */
interface CellSelectionJSON {
    type: string;
    anchor: number;
    head: number;
}
/**
 * A [`Selection`](http://prosemirror.net/docs/ref/#state.Selection)
 * subclass that represents a cell selection spanning part of a table.
 * With the plugin enabled, these will be created when the user
 * selects across cells, and will be drawn by giving selected cells a
 * `selectedCell` CSS class.
 *
 * @public
 */
declare class CellSelection extends Selection {
    $anchorCell: ResolvedPos;
    $headCell: ResolvedPos;
    constructor($anchorCell: ResolvedPos, $headCell?: ResolvedPos);
    map(doc: Node, mapping: Mappable): CellSelection | Selection;
    content(): Slice;
    replace(tr: Transaction, content?: Slice): void;
    replaceWith(tr: Transaction, node: Node): void;
    forEachCell(f: (node: Node, pos: number) => void): void;
    isColSelection(): boolean;
    static colSelection($anchorCell: ResolvedPos, $headCell?: ResolvedPos): CellSelection;
    isRowSelection(): boolean;
    eq(other: unknown): boolean;
    static rowSelection($anchorCell: ResolvedPos, $headCell?: ResolvedPos): CellSelection;
    toJSON(): CellSelectionJSON;
    static fromJSON(doc: Node, json: CellSelectionJSON): CellSelection;
    static create(doc: Node, anchorCell: number, headCell?: number): CellSelection;
    getBookmark(): CellBookmark;
}
/**
 * @public
 */
declare class CellBookmark {
    anchor: number;
    head: number;
    constructor(anchor: number, head: number);
    map(mapping: Mappable): CellBookmark;
    resolve(doc: Node): CellSelection | Selection;
}

/**
 * @public
 */
declare const columnResizingPluginKey: PluginKey<ResizeState>;
/**
 * @public
 */
type ColumnResizingOptions = {
    handleWidth?: number;
    cellMinWidth?: number;
    lastColumnResizable?: boolean;
    /**
     * A custom node view for the rendering table nodes. By default, the plugin
     * uses the {@link TableView} class. You can explicitly set this to `null` to
     * not use a custom node view.
     */
    View?: (new (node: Node, cellMinWidth: number, view: EditorView) => NodeView) | null;
};
/**
 * @public
 */
type Dragging = {
    startX: number;
    startWidth: number;
};
/**
 * @public
 */
declare function columnResizing({ handleWidth, cellMinWidth, View, lastColumnResizable, }?: ColumnResizingOptions): Plugin;
/**
 * @public
 */
declare class ResizeState {
    activeHandle: number;
    dragging: Dragging | false;
    constructor(activeHandle: number, dragging: Dragging | false);
    apply(tr: Transaction): ResizeState;
}

/**
 * @public
 */
type TableRect = Rect & {
    tableStart: number;
    map: TableMap;
    table: Node;
};
/**
 * Helper to get the selected rectangle in a table, if any. Adds table
 * map, table node, and table start offset to the object for
 * convenience.
 *
 * @public
 */
declare function selectedRect(state: EditorState): TableRect;
/**
 * Add a column at the given position in a table.
 *
 * @public
 */
declare function addColumn(tr: Transaction, { map, tableStart, table }: TableRect, col: number): Transaction;
/**
 * Command to add a column before the column with the selection.
 *
 * @public
 */
declare function addColumnBefore(state: EditorState, dispatch?: (tr: Transaction) => void): boolean;
/**
 * Command to add a column after the column with the selection.
 *
 * @public
 */
declare function addColumnAfter(state: EditorState, dispatch?: (tr: Transaction) => void): boolean;
/**
 * @public
 */
declare function removeColumn(tr: Transaction, { map, table, tableStart }: TableRect, col: number): void;
/**
 * Command function that removes the selected columns from a table.
 *
 * @public
 */
declare function deleteColumn(state: EditorState, dispatch?: (tr: Transaction) => void): boolean;
/**
 * @public
 */
declare function rowIsHeader(map: TableMap, table: Node, row: number): boolean;
/**
 * @public
 */
declare function addRow(tr: Transaction, { map, tableStart, table }: TableRect, row: number): Transaction;
/**
 * Add a table row before the selection.
 *
 * @public
 */
declare function addRowBefore(state: EditorState, dispatch?: (tr: Transaction) => void): boolean;
/**
 * Add a table row after the selection.
 *
 * @public
 */
declare function addRowAfter(state: EditorState, dispatch?: (tr: Transaction) => void): boolean;
/**
 * @public
 */
declare function removeRow(tr: Transaction, { map, table, tableStart }: TableRect, row: number): void;
/**
 * Remove the selected rows from a table.
 *
 * @public
 */
declare function deleteRow(state: EditorState, dispatch?: (tr: Transaction) => void): boolean;
/**
 * Merge the selected cells into a single cell. Only available when
 * the selected cells' outline forms a rectangle.
 *
 * @public
 */
declare function mergeCells(state: EditorState, dispatch?: (tr: Transaction) => void): boolean;
/**
 * Split a selected cell, whose rowpan or colspan is greater than one,
 * into smaller cells. Use the first cell type for the new cells.
 *
 * @public
 */
declare function splitCell(state: EditorState, dispatch?: (tr: Transaction) => void): boolean;
/**
 * @public
 */
interface GetCellTypeOptions {
    node: Node;
    row: number;
    col: number;
}
/**
 * Split a selected cell, whose rowpan or colspan is greater than one,
 * into smaller cells with the cell type (th, td) returned by getType function.
 *
 * @public
 */
declare function splitCellWithType(getCellType: (options: GetCellTypeOptions) => NodeType): Command;
/**
 * Returns a command that sets the given attribute to the given value,
 * and is only available when the currently selected cell doesn't
 * already have that attribute set to that value.
 *
 * @public
 */
declare function setCellAttr(name: string, value: unknown): Command;
/**
 * @public
 */
type ToggleHeaderType = 'column' | 'row' | 'cell';
/**
 * Toggles between row/column header and normal cells (Only applies to first row/column).
 * For deprecated behavior pass `useDeprecatedLogic` in options with true.
 *
 * @public
 */
declare function toggleHeader(type: ToggleHeaderType, options?: {
    useDeprecatedLogic: boolean;
} | undefined): Command;
/**
 * Toggles whether the selected row contains header cells.
 *
 * @public
 */
declare const toggleHeaderRow: Command;
/**
 * Toggles whether the selected column contains header cells.
 *
 * @public
 */
declare const toggleHeaderColumn: Command;
/**
 * Toggles whether the selected cells are header cells.
 *
 * @public
 */
declare const toggleHeaderCell: Command;
/**
 * Returns a command for selecting the next (direction=1) or previous
 * (direction=-1) cell in a table.
 *
 * @public
 */
declare function goToNextCell(direction: Direction): Command;
/**
 * Deletes the table around the selection, if any.
 *
 * @public
 */
declare function deleteTable(state: EditorState, dispatch?: (tr: Transaction) => void): boolean;
/**
 * Deletes the content of the selected cells, if they are not empty.
 *
 * @public
 */
declare function deleteCellSelection(state: EditorState, dispatch?: (tr: Transaction) => void): boolean;

/**
 * @internal
 */
type Area = {
    width: number;
    height: number;
    rows: Fragment[];
};
/**
 * Get a rectangular area of cells from a slice, or null if the outer
 * nodes of the slice aren't table cells or rows.
 *
 * @internal
 */
declare function pastedCells(slice: Slice): Area | null;
/**
 * Clip or extend (repeat) the given set of cells to cover the given
 * width and height. Will clip rowspan/colspan cells at the edges when
 * they stick out.
 *
 * @internal
 */
declare function clipCells({ width, height, rows }: Area, newWidth: number, newHeight: number): Area;
/**
 * Insert the given set of cells (as returned by `pastedCells`) into a
 * table, at the position pointed at by rect.
 *
 * @internal
 */
declare function insertCells(state: EditorState, dispatch: (tr: Transaction) => void, tableStart: number, rect: Rect, cells: Area): void;

/**
 * @public
 */
type getFromDOM = (dom: HTMLElement) => unknown;
/**
 * @public
 */
type setDOMAttr = (value: unknown, attrs: MutableAttrs) => void;
/**
 * @public
 */
interface CellAttributes {
    /**
     * The attribute's default value.
     */
    default: unknown;
    /**
     * A function to read the attribute's value from a DOM node.
     */
    getFromDOM?: getFromDOM;
    /**
     * A function to add the attribute's value to an attribute
     * object that's used to render the cell's DOM.
     */
    setDOMAttr?: setDOMAttr;
}
/**
 * @public
 */
interface TableNodesOptions {
    /**
     * A group name (something like `"block"`) to add to the table
     * node type.
     */
    tableGroup?: string;
    /**
     * The content expression for table cells.
     */
    cellContent: string;
    /**
     * Additional attributes to add to cells. Maps attribute names to
     * objects with the following properties:
     */
    cellAttributes: {
        [key: string]: CellAttributes;
    };
}
/**
 * @public
 */
type TableNodes = Record<'table' | 'table_row' | 'table_cell' | 'table_header', NodeSpec>;
/**
 * This function creates a set of [node
 * specs](http://prosemirror.net/docs/ref/#model.SchemaSpec.nodes) for
 * `table`, `table_row`, and `table_cell` nodes types as used by this
 * module. The result can then be added to the set of nodes when
 * creating a schema.
 *
 * @public
 */
declare function tableNodes(options: TableNodesOptions): TableNodes;
/**
 * @public
 */
type TableRole = 'table' | 'row' | 'cell' | 'header_cell';
/**
 * @public
 */
declare function tableNodeTypes(schema: Schema): Record<TableRole, NodeType>;

/**
 * @public
 */
declare class TableView implements NodeView {
    node: Node;
    cellMinWidth: number;
    dom: HTMLDivElement;
    table: HTMLTableElement;
    colgroup: HTMLTableColElement;
    contentDOM: HTMLTableSectionElement;
    constructor(node: Node, cellMinWidth: number);
    update(node: Node): boolean;
    ignoreMutation(record: MutationRecord): boolean;
}
/**
 * @public
 */
declare function updateColumnsOnResize(node: Node, colgroup: HTMLTableColElement, table: HTMLTableElement, cellMinWidth: number, overrideCol?: number, overrideValue?: number): void;

/**
 * @public
 */
type TableEditingOptions = {
    allowTableNodeSelection?: boolean;
};
/**
 * Creates a [plugin](http://prosemirror.net/docs/ref/#state.Plugin)
 * that, when added to an editor, enables cell-selection, handles
 * cell-based copy/paste, and makes sure tables stay well-formed (each
 * row has the same width, and cells don't overlap).
 *
 * You should probably put this plugin near the end of your array of
 * plugins, since it handles mouse and arrow key events in tables
 * rather broadly, and other plugins, like the gap cursor or the
 * column-width dragging plugin, might want to get a turn first to
 * perform more specific behavior.
 *
 * @public
 */
declare function tableEditing({ allowTableNodeSelection, }?: TableEditingOptions): Plugin;

export { type CellAttributes, CellBookmark, CellSelection, type CellSelectionJSON, type ColWidths, type ColumnResizingOptions, type Direction, type Dragging, type GetCellTypeOptions, type MutableAttrs, type Problem, type Rect, ResizeState, type TableEditingOptions, TableMap, type TableNodes, type TableNodesOptions, type TableRect, type TableRole, TableView, type ToggleHeaderType, type Area as __Area, clipCells as __clipCells, insertCells as __insertCells, pastedCells as __pastedCells, addColSpan, addColumn, addColumnAfter, addColumnBefore, addRow, addRowAfter, addRowBefore, cellAround, cellNear, colCount, columnIsHeader, columnResizing, columnResizingPluginKey, deleteCellSelection, deleteColumn, deleteRow, deleteTable, findCell, fixTables, fixTablesKey, type getFromDOM, goToNextCell, handlePaste, inSameTable, isInTable, mergeCells, moveCellForward, nextCell, pointsAtCell, removeColSpan, removeColumn, removeRow, rowIsHeader, selectedRect, selectionCell, setCellAttr, type setDOMAttr, splitCell, splitCellWithType, tableEditing, tableEditingKey, tableNodeTypes, tableNodes, toggleHeader, toggleHeaderCell, toggleHeaderColumn, toggleHeaderRow, updateColumnsOnResize };
