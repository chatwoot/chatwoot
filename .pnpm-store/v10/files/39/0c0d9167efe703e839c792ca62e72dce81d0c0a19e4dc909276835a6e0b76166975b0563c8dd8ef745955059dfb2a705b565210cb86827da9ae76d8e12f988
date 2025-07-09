import { Selection, Plugin } from 'prosemirror-state';
import { ResolvedPos, Node, Slice } from 'prosemirror-model';
import { Mappable } from 'prosemirror-transform';

/**
Gap cursor selections are represented using this class. Its
`$anchor` and `$head` properties both point at the cursor position.
*/
declare class GapCursor extends Selection {
    /**
    Create a gap cursor.
    */
    constructor($pos: ResolvedPos);
    map(doc: Node, mapping: Mappable): Selection;
    content(): Slice;
    eq(other: Selection): boolean;
    toJSON(): any;
}

/**
Create a gap cursor plugin. When enabled, this will capture clicks
near and arrow-key-motion past places that don't have a normally
selectable position nearby, and create a gap cursor selection for
them. The cursor is drawn as an element with class
`ProseMirror-gapcursor`. You can either include
`style/gapcursor.css` from the package's directory or add your own
styles to make it visible.
*/
declare function gapCursor(): Plugin;

export { GapCursor, gapCursor };
