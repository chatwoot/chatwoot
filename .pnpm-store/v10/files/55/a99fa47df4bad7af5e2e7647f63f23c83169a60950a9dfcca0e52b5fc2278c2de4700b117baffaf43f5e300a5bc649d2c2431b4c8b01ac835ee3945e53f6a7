# Utils library for ProseMirror

[![npm](https://img.shields.io/npm/v/prosemirror-utils.svg?style=flat-square)](https://www.npmjs.com/package/prosemirror-utils)
[![License](https://img.shields.io/npm/l/prosemirror-utils.svg?style=flat-square)](http://www.apache.org/licenses/LICENSE-2.0)
[![Github Issues](https://img.shields.io/github/issues/atlassian/prosemirror-utils.svg?style=flat-square)](https://github.com/atlassian/prosemirror-utils/issues)
[![CircleCI](https://img.shields.io/circleci/project/github/atlassian/prosemirror-utils.svg?style=flat-square)](https://circleci.com/gh/atlassian/prosemirror-utils)
[![codecov](https://codecov.io/gh/atlassian/prosemirror-utils/branch/master/graph/badge.svg)](https://codecov.io/gh/atlassian/prosemirror-utils)
[![Downloads](https://img.shields.io/npm/dw/prosemirror-utils.svg?style=flat-square)](https://www.npmjs.com/package/prosemirror-utils)
[![Code size](https://img.shields.io/github/languages/code-size/atlassian/prosemirror-utils.svg?style=flat-square)](https://www.npmjs.com/package/prosemirror-utils)


## How to

### Test

```sh
npm run test
```

### Build

```sh
npm run build_all
```

## Quick Start

Install `prosemirror-utils` package from npm:

```sh
npm install prosemirror-utils
```

## Public API documentation

### Utils for working with `selection`

 * **`findParentNode`**`(predicate: fn(node: ProseMirrorNode) → boolean) → fn(selection: Selection) → ?{pos: number, start: number, depth: number, node: ProseMirrorNode}`\
   Iterates over parent nodes, returning the closest node and its start position `predicate` returns truthy for. `start` points to the start position of the node, `pos` points directly before the node.

   ```javascript
   const predicate = node => node.type === schema.nodes.blockquote;
   const parent = findParentNode(predicate)(selection);
   ```


 * **`findParentNodeClosestToPos`**`($pos: ResolvedPos, predicate: fn(node: ProseMirrorNode) → boolean) → ?{pos: number, start: number, depth: number, node: ProseMirrorNode}`\
   Iterates over parent nodes starting from the given `$pos`, returning the closest node and its start position `predicate` returns truthy for. `start` points to the start position of the node, `pos` points directly before the node.

   ```javascript
   const predicate = node => node.type === schema.nodes.blockquote;
   const parent = findParentNodeClosestToPos(state.doc.resolve(5), predicate);
   ```


 * **`findParentDomRef`**`(predicate: fn(node: ProseMirrorNode) → boolean, domAtPos: fn(pos: number) → {node: dom.Node, offset: number}) → fn(selection: Selection) → ?dom.Node`\
   Iterates over parent nodes, returning DOM reference of the closest node `predicate` returns truthy for.

   ```javascript
   const domAtPos = view.domAtPos.bind(view);
   const predicate = node => node.type === schema.nodes.table;
   const parent = findParentDomRef(predicate, domAtPos)(selection); // <table>
   ```


 * **`hasParentNode`**`(predicate: fn(node: ProseMirrorNode) → boolean) → fn(selection: Selection) → boolean`\
   Checks if there's a parent node `predicate` returns truthy for.

   ```javascript
   if (hasParentNode(node => node.type === schema.nodes.table)(selection)) {
     // ....
   }
   ```


 * **`findParentNodeOfType`**`(nodeType: NodeType | [NodeType]) → fn(selection: Selection) → ?{pos: number, start: number, depth: number, node: ProseMirrorNode}`\
   Iterates over parent nodes, returning closest node of a given `nodeType`. `start` points to the start position of the node, `pos` points directly before the node.

   ```javascript
   const parent = findParentNodeOfType(schema.nodes.paragraph)(selection);
   ```


 * **`findParentNodeOfTypeClosestToPos`**`($pos: ResolvedPos, nodeType: NodeType | [NodeType]) → ?{pos: number, start: number, depth: number, node: ProseMirrorNode}`\
   Iterates over parent nodes starting from the given `$pos`, returning closest node of a given `nodeType`. `start` points to the start position of the node, `pos` points directly before the node.

   ```javascript
   const parent = findParentNodeOfTypeClosestToPos(state.doc.resolve(10), schema.nodes.paragraph);
   ```


 * **`hasParentNodeOfType`**`(nodeType: NodeType | [NodeType]) → fn(selection: Selection) → boolean`\
   Checks if there's a parent node of a given `nodeType`.

   ```javascript
   if (hasParentNodeOfType(schema.nodes.table)(selection)) {
     // ....
   }
   ```


 * **`findParentDomRefOfType`**`(nodeType: NodeType | [NodeType], domAtPos: fn(pos: number) → {node: dom.Node, offset: number}) → fn(selection: Selection) → ?dom.Node`\
   Iterates over parent nodes, returning DOM reference of the closest node of a given `nodeType`.

   ```javascript
   const domAtPos = view.domAtPos.bind(view);
   const parent = findParentDomRefOfType(schema.nodes.codeBlock, domAtPos)(selection); // <pre>
   ```


 * **`findSelectedNodeOfType`**`(nodeType: NodeType | [NodeType]) → fn(selection: Selection) → ?{pos: number, start: number, depth: number, node: ProseMirrorNode}`\
   Returns a node of a given `nodeType` if it is selected. `start` points to the start position of the node, `pos` points directly before the node.

   ```javascript
   const { extension, inlineExtension, bodiedExtension } = schema.nodes;
   const selectedNode = findSelectedNodeOfType([
     extension,
     inlineExtension,
     bodiedExtension,
   ])(selection);
   ```


 * **`isNodeSelection`**`(selection: Selection) → boolean`\
   Checks if current selection is a `NodeSelection`.

   ```javascript
   if (isNodeSelection(tr.selection)) {
     // ...
   }
   ```


 * **`findPositionOfNodeBefore`**`(selection: Selection) → ?number`\
   Returns position of the previous node.

   ```javascript
   const pos = findPositionOfNodeBefore(tr.selection);
   ```


 * **`findDomRefAtPos`**`(position: number, domAtPos: fn(pos: number) → {node: dom.Node, offset: number}) → dom.Node`\
   Returns DOM reference of a node at a given `position`. If the node type is of type `TEXT_NODE` it will return the reference of the parent node.

   ```javascript
   const domAtPos = view.domAtPos.bind(view);
   const ref = findDomRefAtPos($from.pos, domAtPos);
   ```


### Utils for working with ProseMirror `node`

 * **`flatten`**`(node: ProseMirrorNode, descend: ?boolean = true) → [{node: ProseMirrorNode, pos: number}]`\
   Flattens descendants of a given `node`. It doesn't descend into a node when descend argument is `false` (defaults to `true`).

   ```javascript
   const children = flatten(node);
   ```


 * **`findChildren`**`(node: ProseMirrorNode, predicate: fn(node: ProseMirrorNode) → boolean, descend: ?boolean) → [{node: ProseMirrorNode, pos: number}]`\
   Iterates over descendants of a given `node`, returning child nodes predicate returns truthy for. It doesn't descend into a node when descend argument is `false` (defaults to `true`).

   ```javascript
   const textNodes = findChildren(node, child => child.isText, false);
   ```


 * **`findTextNodes`**`(node: ProseMirrorNode, descend: ?boolean) → [{node: ProseMirrorNode, pos: number}]`\
   Returns text nodes of a given `node`. It doesn't descend into a node when descend argument is `false` (defaults to `true`).

   ```javascript
   const textNodes = findTextNodes(node);
   ```


 * **`findInlineNodes`**`(node: ProseMirrorNode, descend: ?boolean) → [{node: ProseMirrorNode, pos: number}]`\
   Returns inline nodes of a given `node`. It doesn't descend into a node when descend argument is `false` (defaults to `true`).

   ```javascript
   const inlineNodes = findInlineNodes(node);
   ```


 * **`findBlockNodes`**`(node: ProseMirrorNode, descend: ?boolean) → [{node: ProseMirrorNode, pos: number}]`\
   Returns block descendants of a given `node`. It doesn't descend into a node when descend argument is `false` (defaults to `true`).

   ```javascript
   const blockNodes = findBlockNodes(node);
   ```


 * **`findChildrenByAttr`**`(node: ProseMirrorNode, predicate: fn(attrs: ?Object) → boolean, descend: ?boolean) → [{node: ProseMirrorNode, pos: number}]`\
   Iterates over descendants of a given `node`, returning child nodes predicate returns truthy for. It doesn't descend into a node when descend argument is `false` (defaults to `true`).

   ```javascript
   const mergedCells = findChildrenByAttr(table, attrs => attrs.colspan === 2);
   ```


 * **`findChildrenByType`**`(node: ProseMirrorNode, nodeType: NodeType, descend: ?boolean) → [{node: ProseMirrorNode, pos: number}]`\
   Iterates over descendants of a given `node`, returning child nodes of a given nodeType. It doesn't descend into a node when descend argument is `false` (defaults to `true`).

   ```javascript
   const cells = findChildrenByType(table, schema.nodes.tableCell);
   ```


 * **`findChildrenByMark`**`(node: ProseMirrorNode, markType: markType, descend: ?boolean) → [{node: ProseMirrorNode, pos: number}]`\
   Iterates over descendants of a given `node`, returning child nodes that have a mark of a given markType. It doesn't descend into a `node` when descend argument is `false` (defaults to `true`).

   ```javascript
   const nodes = findChildrenByMark(state.doc, schema.marks.strong);
   ```


 * **`contains`**`(node: ProseMirrorNode, nodeType: NodeType) → boolean`\
   Returns `true` if a given node contains nodes of a given `nodeType`

   ```javascript
   if (contains(panel, schema.nodes.listItem)) {
     // ...
   }
   ```


### Utils for document transformation

 * **`removeParentNodeOfType`**`(nodeType: NodeType | [NodeType]) → fn(tr: Transaction) → Transaction`\
   Returns a new transaction that removes a node of a given `nodeType`. It will return an original transaction if parent node hasn't been found.

   ```javascript
   dispatch(
     removeParentNodeOfType(schema.nodes.table)(tr)
   );
   ```


 * **`replaceParentNodeOfType`**`(nodeType: NodeType | [NodeType], content: ProseMirrorNode | Fragment) → fn(tr: Transaction) → Transaction`\
   Returns a new transaction that replaces parent node of a given `nodeType` with the given `content`. It will return an original transaction if either parent node hasn't been found or replacing is not possible.

   ```javascript
   const node = schema.nodes.paragraph.createChecked({}, schema.text('new'));

   dispatch(
    replaceParentNodeOfType(schema.nodes.table, node)(tr)
   );
   ```


 * **`removeSelectedNode`**`(tr: Transaction) → Transaction`\
   Returns a new transaction that removes selected node. It will return an original transaction if current selection is not a `NodeSelection`.

   ```javascript
   dispatch(
     removeSelectedNode(tr)
   );
   ```


 * **`replaceSelectedNode`**`(content: ProseMirrorNode | ProseMirrorFragment) → fn(tr: Transaction) → Transaction`\
   Returns a new transaction that replaces selected node with a given `node`, keeping NodeSelection on the new `node`.
   It will return the original transaction if either current selection is not a NodeSelection or replacing is not possible.

   ```javascript
   const node = schema.nodes.paragraph.createChecked({}, schema.text('new'));
   dispatch(
     replaceSelectedNode(node)(tr)
   );
   ```


 * **`canInsert`**`($pos: ResolvedPos, content: ProseMirrorNode | Fragment) → boolean`\
   Checks if a given `content` can be inserted at the given `$pos`

   ```javascript
   const { selection: { $from } } = state;
   const node = state.schema.nodes.atom.createChecked();
   if (canInsert($from, node)) {
     // ...
   }
   ```


 * **`safeInsert`**`(content: ProseMirrorNode | Fragment, position: ?number, tryToReplace: ?boolean) → fn(tr: Transaction) → Transaction`\
   Returns a new transaction that inserts a given `content` at the current cursor position, or at a given `position`, if it is allowed by schema. If schema restricts such nesting, it will try to find an appropriate place for a given node in the document, looping through parent nodes up until the root document node.
   If `tryToReplace` is true and current selection is a NodeSelection, it will replace selected node with inserted content if its allowed by schema.
   If cursor is inside of an empty paragraph, it will try to replace that paragraph with the given content. If insertion is successful and inserted node has content, it will set cursor inside of that content.
   It will return an original transaction if the place for insertion hasn't been found.

   ```javascript
   const node = schema.nodes.extension.createChecked({});
   dispatch(
     safeInsert(node)(tr)
   );
   ```


 * **`setParentNodeMarkup`**`(nodeType: NodeType | [NodeType], type: ?NodeType | null, attrs: ?Object | null, marks: ?[Mark]) → fn(tr: Transaction) → Transaction`\
   Returns a transaction that changes the type, attributes, and/or marks of the parent node of a given `nodeType`.

   ```javascript
   const node = schema.nodes.extension.createChecked({});
   dispatch(
     setParentNodeMarkup(schema.nodes.panel, null, { panelType })(tr);
   );
   ```


 * **`selectParentNodeOfType`**`(nodeType: NodeType | [NodeType]) → fn(tr: Transaction) → Transaction`\
   Returns a new transaction that sets a `NodeSelection` on a parent node of a `given nodeType`.

   ```javascript
   dispatch(
     selectParentNodeOfType([tableCell, tableHeader])(state.tr)
   );
   ```


 * **`removeNodeBefore`**`(tr: Transaction) → Transaction`\
   Returns a new transaction that deletes previous node.

   ```javascript
   dispatch(
     removeNodeBefore(state.tr)
   );
   ```


 * **`setTextSelection`**`(position: number, dir: ?number = 1) → fn(tr: Transaction) → Transaction`\
   Returns a new transaction that tries to find a valid cursor selection starting at the given `position`
   and searching back if `dir` is negative, and forward if positive.
   If a valid cursor position hasn't been found, it will return the original transaction.

   ```javascript
   dispatch(
     setTextSelection(5)(tr)
   );
   ```


## License

- **Apache 2.0** : http://www.apache.org/licenses/LICENSE-2.0

