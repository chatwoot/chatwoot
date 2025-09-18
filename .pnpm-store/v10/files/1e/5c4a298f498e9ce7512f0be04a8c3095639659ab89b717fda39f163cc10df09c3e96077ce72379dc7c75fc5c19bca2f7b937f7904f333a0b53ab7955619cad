import { EditorView } from 'prosemirror-view';
import { EditorState, Transaction, Plugin } from 'prosemirror-state';
import { NodeType, Attrs } from 'prosemirror-model';

/**
The types defined in this module aren't the only thing you can
display in your menu. Anything that conforms to this interface can
be put into a menu structure.
*/
interface MenuElement {
    /**
    Render the element for display in the menu. Must return a DOM
    element and a function that can be used to update the element to
    a new state. The `update` function must return false if the
    update hid the entire element.
    */
    render(pm: EditorView): {
        dom: HTMLElement;
        update: (state: EditorState) => boolean;
    };
}
/**
An icon or label that, when clicked, executes a command.
*/
declare class MenuItem implements MenuElement {
    /**
    The spec used to create this item.
    */
    readonly spec: MenuItemSpec;
    /**
    Create a menu item.
    */
    constructor(
    /**
    The spec used to create this item.
    */
    spec: MenuItemSpec);
    /**
    Renders the icon according to its [display
    spec](https://prosemirror.net/docs/ref/#menu.MenuItemSpec.display), and adds an event handler which
    executes the command when the representation is clicked.
    */
    render(view: EditorView): {
        dom: HTMLElement;
        update: (state: EditorState) => boolean;
    };
}
/**
Specifies an icon. May be either an SVG icon, in which case its
`path` property should be an [SVG path
spec](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d),
and `width` and `height` should provide the viewbox in which that
path exists. Alternatively, it may have a `text` property
specifying a string of text that makes up the icon, with an
optional `css` property giving additional CSS styling for the
text. _Or_ it may contain `dom` property containing a DOM node.
*/
type IconSpec = {
    path: string;
    width: number;
    height: number;
} | {
    text: string;
    css?: string;
} | {
    dom: Node;
};
/**
The configuration object passed to the `MenuItem` constructor.
*/
interface MenuItemSpec {
    /**
    The function to execute when the menu item is activated.
    */
    run: (state: EditorState, dispatch: (tr: Transaction) => void, view: EditorView, event: Event) => void;
    /**
    Optional function that is used to determine whether the item is
    appropriate at the moment. Deselected items will be hidden.
    */
    select?: (state: EditorState) => boolean;
    /**
    Function that is used to determine if the item is enabled. If
    given and returning false, the item will be given a disabled
    styling.
    */
    enable?: (state: EditorState) => boolean;
    /**
    A predicate function to determine whether the item is 'active' (for
    example, the item for toggling the strong mark might be active then
    the cursor is in strong text).
    */
    active?: (state: EditorState) => boolean;
    /**
    A function that renders the item. You must provide either this,
    [`icon`](https://prosemirror.net/docs/ref/#menu.MenuItemSpec.icon), or [`label`](https://prosemirror.net/docs/ref/#MenuItemSpec.label).
    */
    render?: (view: EditorView) => HTMLElement;
    /**
    Describes an icon to show for this item.
    */
    icon?: IconSpec;
    /**
    Makes the item show up as a text label. Mostly useful for items
    wrapped in a [drop-down](https://prosemirror.net/docs/ref/#menu.Dropdown) or similar menu. The object
    should have a `label` property providing the text to display.
    */
    label?: string;
    /**
    Defines DOM title (mouseover) text for the item.
    */
    title?: string | ((state: EditorState) => string);
    /**
    Optionally adds a CSS class to the item's DOM representation.
    */
    class?: string;
    /**
    Optionally adds a string of inline CSS to the item's DOM
    representation.
    */
    css?: string;
}
/**
A drop-down menu, displayed as a label with a downwards-pointing
triangle to the right of it.
*/
declare class Dropdown implements MenuElement {
    /**
    Create a dropdown wrapping the elements.
    */
    constructor(content: readonly MenuElement[] | MenuElement, 
    /**
    @internal
    */
    options?: {
        /**
        The label to show on the drop-down control.
        */
        label?: string;
        /**
        Sets the
        [`title`](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/title)
        attribute given to the menu control.
        */
        title?: string;
        /**
        When given, adds an extra CSS class to the menu control.
        */
        class?: string;
        /**
        When given, adds an extra set of CSS styles to the menu control.
        */
        css?: string;
    });
    /**
    Render the dropdown menu and sub-items.
    */
    render(view: EditorView): {
        dom: HTMLElement;
        update: (state: EditorState) => boolean;
    };
}
/**
Represents a submenu wrapping a group of elements that start
hidden and expand to the right when hovered over or tapped.
*/
declare class DropdownSubmenu implements MenuElement {
    /**
    Creates a submenu for the given group of menu elements. The
    following options are recognized:
    */
    constructor(content: readonly MenuElement[] | MenuElement, 
    /**
    @internal
    */
    options?: {
        /**
        The label to show on the submenu.
        */
        label?: string;
    });
    /**
    Renders the submenu.
    */
    render(view: EditorView): {
        dom: HTMLElement;
        update: (state: EditorState) => boolean;
    };
}
/**
Render the given, possibly nested, array of menu elements into a
document fragment, placing separators between them (and ensuring no
superfluous separators appear when some of the groups turn out to
be empty).
*/
declare function renderGrouped(view: EditorView, content: readonly (readonly MenuElement[])[]): {
    dom: DocumentFragment;
    update: (state: EditorState) => boolean;
};
/**
A set of basic editor-related icons. Contains the properties
`join`, `lift`, `selectParentNode`, `undo`, `redo`, `strong`, `em`,
`code`, `link`, `bulletList`, `orderedList`, and `blockquote`, each
holding an object that can be used as the `icon` option to
`MenuItem`.
*/
declare const icons: {
    [name: string]: IconSpec;
};
/**
Menu item for the `joinUp` command.
*/
declare const joinUpItem: MenuItem;
/**
Menu item for the `lift` command.
*/
declare const liftItem: MenuItem;
/**
Menu item for the `selectParentNode` command.
*/
declare const selectParentNodeItem: MenuItem;
/**
Menu item for the `undo` command.
*/
declare let undoItem: MenuItem;
/**
Menu item for the `redo` command.
*/
declare let redoItem: MenuItem;
/**
Build a menu item for wrapping the selection in a given node type.
Adds `run` and `select` properties to the ones present in
`options`. `options.attrs` may be an object that provides
attributes for the wrapping node.
*/
declare function wrapItem(nodeType: NodeType, options: Partial<MenuItemSpec> & {
    attrs?: Attrs | null;
}): MenuItem;
/**
Build a menu item for changing the type of the textblock around the
selection to the given type. Provides `run`, `active`, and `select`
properties. Others must be given in `options`. `options.attrs` may
be an object to provide the attributes for the textblock node.
*/
declare function blockTypeItem(nodeType: NodeType, options: Partial<MenuItemSpec> & {
    attrs?: Attrs | null;
}): MenuItem;

/**
A plugin that will place a menu bar above the editor. Note that
this involves wrapping the editor in an additional `<div>`.
*/
declare function menuBar(options: {
    /**
    Provides the content of the menu, as a nested array to be
    passed to `renderGrouped`.
    */
    content: readonly (readonly MenuElement[])[];
    /**
    Determines whether the menu floats, i.e. whether it sticks to
    the top of the viewport when the editor is partially scrolled
    out of view.
    */
    floating?: boolean;
}): Plugin;

export { Dropdown, DropdownSubmenu, IconSpec, MenuElement, MenuItem, MenuItemSpec, blockTypeItem, icons, joinUpItem, liftItem, menuBar, redoItem, renderGrouped, selectParentNodeItem, undoItem, wrapItem };
