# prosemirror-menu

[ [**WEBSITE**](https://prosemirror.net) | [**ISSUES**](https://github.com/prosemirror/prosemirror-menu/issues) | [**FORUM**](https://discuss.prosemirror.net) | [**GITTER**](https://gitter.im/ProseMirror/prosemirror) ]

This is a non-core example module for [ProseMirror](https://prosemirror.net).
ProseMirror is a well-behaved rich semantic content editor based on
contentEditable, with support for collaborative editing and custom
document schemas.

This module defines an abstraction for building a menu for the
ProseMirror editor, along with an implementation of a menubar.

**Note** that this module exists mostly as an example of how you
_might_ want to approach adding a menu to ProseMirror, but is not
maintained as actively as the core modules related to actual editing.
If you want to extend or improve it, the recommended way is to fork
it. If you are interested in maintaining a serious menu component for
ProseMirror, publish your fork, and if it works for me, I'll gladly
deprecate this in favor of your module.

This code is released under an
[MIT license](https://github.com/prosemirror/prosemirror/tree/master/LICENSE).
There's a [forum](http://discuss.prosemirror.net) for general
discussion and support requests, and the
[Github bug tracker](https://github.com/prosemirror/prosemirror-menu/issues)
is the place to report issues.

## Documentation

This module defines a number of building blocks for ProseMirror menus,
along with a [menu bar](#menu.menuBar) implementation.

When using this module, you should make sure its
[`style/menu.css`](https://github.com/ProseMirror/prosemirror-menu/blob/master/style/menu.css)
file is loaded into your page.

### interface MenuElement

The types defined in this module aren't the only thing you can
display in your menu. Anything that conforms to this interface can
be put into a menu structure.

 * **`render`**`(pm: EditorView) → {dom: HTMLElement, update: fn(state: EditorState) → boolean}`\
   Render the element for display in the menu. Must return a DOM
   element and a function that can be used to update the element to
   a new state. The `update` function must return false if the
   update hid the entire element.

### class MenuItem

 implements `MenuElement`An icon or label that, when clicked, executes a command.

 * `new `**`MenuItem`**`(spec: MenuItemSpec)`\
   Create a menu item.

 * **`spec`**`: MenuItemSpec`\
   The spec used to create this item.

 * **`render`**`(view: EditorView) → {dom: HTMLElement, update: fn(state: EditorState) → boolean}`\
   Renders the icon according to its [display
   spec](#menu.MenuItemSpec.display), and adds an event handler which
   executes the command when the representation is clicked.

### interface MenuItemSpec

The configuration object passed to the `MenuItem` constructor.

 * **`run`**`(state: EditorState, dispatch: fn(tr: Transaction), view: EditorView, event: Event)`\
   The function to execute when the menu item is activated.

 * **`select`**`: ?fn(state: EditorState) → boolean`\
   Optional function that is used to determine whether the item is
   appropriate at the moment. Deselected items will be hidden.

 * **`enable`**`: ?fn(state: EditorState) → boolean`\
   Function that is used to determine if the item is enabled. If
   given and returning false, the item will be given a disabled
   styling.

 * **`active`**`: ?fn(state: EditorState) → boolean`\
   A predicate function to determine whether the item is 'active' (for
   example, the item for toggling the strong mark might be active then
   the cursor is in strong text).

 * **`render`**`: ?fn(view: EditorView) → HTMLElement`\
   A function that renders the item. You must provide either this,
   [`icon`](#menu.MenuItemSpec.icon), or [`label`](#MenuItemSpec.label).

 * **`icon`**`: ?IconSpec`\
   Describes an icon to show for this item.

 * **`label`**`: ?string`\
   Makes the item show up as a text label. Mostly useful for items
   wrapped in a [drop-down](#menu.Dropdown) or similar menu. The object
   should have a `label` property providing the text to display.

 * **`title`**`: ?string | fn(state: EditorState) → string`\
   Defines DOM title (mouseover) text for the item.

 * **`class`**`: ?string`\
   Optionally adds a CSS class to the item's DOM representation.

 * **`css`**`: ?string`\
   Optionally adds a string of inline CSS to the item's DOM
   representation.

 * type **`IconSpec`**
   ` = {path: string, width: number, height: number} | {text: string, css?: ?string} | {dom: Node}`\
   Specifies an icon. May be either an SVG icon, in which case its
   `path` property should be an [SVG path
   spec](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d),
   and `width` and `height` should provide the viewbox in which that
   path exists. Alternatively, it may have a `text` property
   specifying a string of text that makes up the icon, with an
   optional `css` property giving additional CSS styling for the
   text. _Or_ it may contain `dom` property containing a DOM node.

### class Dropdown

 implements `MenuElement`A drop-down menu, displayed as a label with a downwards-pointing
triangle to the right of it.

 * `new `**`Dropdown`**`(content: readonly MenuElement[] | MenuElement, options: ?Object = {})`\
   Create a dropdown wrapping the elements.

 * **`render`**`(view: EditorView) → {dom: HTMLElement, update: fn(state: EditorState) → boolean}`\
   Render the dropdown menu and sub-items.

### class DropdownSubmenu

 implements `MenuElement`Represents a submenu wrapping a group of elements that start
hidden and expand to the right when hovered over or tapped.

 * `new `**`DropdownSubmenu`**`(content: readonly MenuElement[] | MenuElement, options: ?Object = {})`\
   Creates a submenu for the given group of menu elements. The
   following options are recognized:

 * **`render`**`(view: EditorView) → {dom: HTMLElement, update: fn(state: EditorState) → boolean}`\
   Renders the submenu.

 * **`menuBar`**`(options: Object) → Plugin`\
   A plugin that will place a menu bar above the editor. Note that
   this involves wrapping the editor in an additional `<div>`.


This module exports the following pre-built items or item
constructors:

 * **`joinUpItem`**`: MenuItem`\
   Menu item for the `joinUp` command.

 * **`liftItem`**`: MenuItem`\
   Menu item for the `lift` command.

 * **`selectParentNodeItem`**`: MenuItem`\
   Menu item for the `selectParentNode` command.

 * **`undoItem`**`: MenuItem`\
   Menu item for the `undo` command.

 * **`redoItem`**`: MenuItem`\
   Menu item for the `redo` command.

 * **`wrapItem`**`(nodeType: NodeType, options: Partial & {attrs?: ?Attrs}) → MenuItem`\
   Build a menu item for wrapping the selection in a given node type.
   Adds `run` and `select` properties to the ones present in
   `options`. `options.attrs` may be an object that provides
   attributes for the wrapping node.

 * **`blockTypeItem`**`(nodeType: NodeType, options: Partial & {attrs?: ?Attrs}) → MenuItem`\
   Build a menu item for changing the type of the textblock around the
   selection to the given type. Provides `run`, `active`, and `select`
   properties. Others must be given in `options`. `options.attrs` may
   be an object to provide the attributes for the textblock node.


To construct your own items, these icons may be useful:

 * **`icons`**`: Object`\
   A set of basic editor-related icons. Contains the properties
   `join`, `lift`, `selectParentNode`, `undo`, `redo`, `strong`, `em`,
   `code`, `link`, `bulletList`, `orderedList`, and `blockquote`, each
   holding an object that can be used as the `icon` option to
   `MenuItem`.


 * **`renderGrouped`**`(view: EditorView, content: readonly readonly MenuElement[][]) → {`\
   `  dom: DocumentFragment,`\
   `  update: fn(state: EditorState) → boolean`\
   `}`\
   Render the given, possibly nested, array of menu elements into a
   document fragment, placing separators between them (and ensuring no
   superfluous separators appear when some of the groups turn out to
   be empty).

