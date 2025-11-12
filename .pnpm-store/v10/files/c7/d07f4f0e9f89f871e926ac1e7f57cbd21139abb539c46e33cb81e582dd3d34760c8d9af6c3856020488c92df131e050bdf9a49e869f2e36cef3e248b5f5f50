import { Plugin } from 'prosemirror-state';

interface DropCursorOptions {
    /**
    The color of the cursor. Defaults to `black`. Use `false` to apply no color and rely only on class.
    */
    color?: string | false;
    /**
    The precise width of the cursor in pixels. Defaults to 1.
    */
    width?: number;
    /**
    A CSS class name to add to the cursor element.
    */
    class?: string;
}
/**
Create a plugin that, when added to a ProseMirror instance,
causes a decoration to show up at the drop position when something
is dragged over the editor.

Nodes may add a `disableDropCursor` property to their spec to
control the showing of a drop cursor inside them. This may be a
boolean or a function, which will be called with a view and a
position, and should return a boolean.
*/
declare function dropCursor(options?: DropCursorOptions): Plugin;

export { dropCursor };
