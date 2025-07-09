import { NodeSpec, NodeType, Attrs } from 'prosemirror-model';
import OrderedMap from 'orderedmap';
import { Command } from 'prosemirror-state';

/**
An ordered list [node spec](https://prosemirror.net/docs/ref/#model.NodeSpec). Has a single
attribute, `order`, which determines the number at which the list
starts counting, and defaults to 1. Represented as an `<ol>`
element.
*/
declare const orderedList: NodeSpec;
/**
A bullet list node spec, represented in the DOM as `<ul>`.
*/
declare const bulletList: NodeSpec;
/**
A list item (`<li>`) spec.
*/
declare const listItem: NodeSpec;
/**
Convenience function for adding list-related node types to a map
specifying the nodes for a schema. Adds
[`orderedList`](https://prosemirror.net/docs/ref/#schema-list.orderedList) as `"ordered_list"`,
[`bulletList`](https://prosemirror.net/docs/ref/#schema-list.bulletList) as `"bullet_list"`, and
[`listItem`](https://prosemirror.net/docs/ref/#schema-list.listItem) as `"list_item"`.

`itemContent` determines the content expression for the list items.
If you want the commands defined in this module to apply to your
list structure, it should have a shape like `"paragraph block*"` or
`"paragraph (ordered_list | bullet_list)*"`. `listGroup` can be
given to assign a group name to the list node types, for example
`"block"`.
*/
declare function addListNodes(nodes: OrderedMap<NodeSpec>, itemContent: string, listGroup?: string): OrderedMap<NodeSpec>;
/**
Returns a command function that wraps the selection in a list with
the given type an attributes. If `dispatch` is null, only return a
value to indicate whether this is possible, but don't actually
perform the change.
*/
declare function wrapInList(listType: NodeType, attrs?: Attrs | null): Command;
/**
Build a command that splits a non-empty textblock at the top level
of a list item by also splitting that list item.
*/
declare function splitListItem(itemType: NodeType, itemAttrs?: Attrs): Command;
/**
Acts like [`splitListItem`](https://prosemirror.net/docs/ref/#schema-list.splitListItem), but
without resetting the set of active marks at the cursor.
*/
declare function splitListItemKeepMarks(itemType: NodeType, itemAttrs?: Attrs): Command;
/**
Create a command to lift the list item around the selection up into
a wrapping list.
*/
declare function liftListItem(itemType: NodeType): Command;
/**
Create a command to sink the list item around the selection down
into an inner list.
*/
declare function sinkListItem(itemType: NodeType): Command;

export { addListNodes, bulletList, liftListItem, listItem, orderedList, sinkListItem, splitListItem, splitListItemKeepMarks, wrapInList };
