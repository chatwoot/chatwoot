// src/selection.ts
import { Selection as Selection3 } from "prosemirror-state";

// src/helpers.ts
import { NodeSelection as NodeSelection2 } from "prosemirror-state";
import { Fragment as Fragment2, Node as PMNode2 } from "prosemirror-model";

// src/transforms.ts
import { NodeSelection, Selection } from "prosemirror-state";
import {
  Fragment,
  Node as PMNode
} from "prosemirror-model";
var removeParentNodeOfType = (nodeType) => (tr) => {
  const parent = findParentNodeOfType(nodeType)(tr.selection);
  if (parent) {
    return removeNodeAtPos(parent.pos)(tr);
  }
  return tr;
};
var replaceParentNodeOfType = (nodeType, content) => (tr) => {
  if (!Array.isArray(nodeType)) {
    nodeType = [nodeType];
  }
  for (let i = 0, count = nodeType.length; i < count; i++) {
    const parent = findParentNodeOfType(nodeType[i])(tr.selection);
    if (parent) {
      const newTr = replaceNodeAtPos(parent.pos, content)(tr);
      if (newTr !== tr) {
        return newTr;
      }
    }
  }
  return tr;
};
var removeSelectedNode = (tr) => {
  if (isNodeSelection(tr.selection)) {
    const from = tr.selection.$from.pos;
    const to = tr.selection.$to.pos;
    return cloneTr(tr.delete(from, to));
  }
  return tr;
};
var replaceSelectedNode = (content) => (tr) => {
  if (isNodeSelection(tr.selection)) {
    const { $from, $to } = tr.selection;
    if (content instanceof Fragment && $from.parent.canReplace(
      $from.index(),
      $from.indexAfter(),
      content
    ) || content instanceof PMNode && $from.parent.canReplaceWith(
      $from.index(),
      $from.indexAfter(),
      content.type
    )) {
      return cloneTr(
        tr.replaceWith($from.pos, $to.pos, content).setSelection(new NodeSelection(tr.doc.resolve($from.pos)))
      );
    }
  }
  return tr;
};
var setTextSelection = (position, dir = 1) => (tr) => {
  const nextSelection = Selection.findFrom(
    tr.doc.resolve(position),
    dir,
    true
  );
  if (nextSelection) {
    return tr.setSelection(nextSelection);
  }
  return tr;
};
var isSelectableNode = (node) => Boolean(node instanceof PMNode && node.type && node.type.spec.selectable);
var shouldSelectNode = (node) => isSelectableNode(node) && node.type.isLeaf;
var setSelection = (node, pos, tr) => {
  if (shouldSelectNode(node)) {
    return tr.setSelection(new NodeSelection(tr.doc.resolve(pos)));
  }
  return setTextSelection(pos)(tr);
};
var safeInsert = (content, position, tryToReplace) => (tr) => {
  const hasPosition = typeof position === "number";
  const { $from } = tr.selection;
  const $insertPos = hasPosition ? tr.doc.resolve(position) : isNodeSelection(tr.selection) ? tr.doc.resolve($from.pos + 1) : $from;
  const { parent } = $insertPos;
  if (isNodeSelection(tr.selection) && tryToReplace) {
    const oldTr = tr;
    tr = replaceSelectedNode(content)(tr);
    if (oldTr !== tr) {
      return tr;
    }
  }
  if (isEmptyParagraph(parent)) {
    const oldTr = tr;
    tr = replaceParentNodeOfType(parent.type, content)(tr);
    if (oldTr !== tr) {
      const pos = isSelectableNode(content) ? (
        // for selectable node, selection position would be the position of the replaced parent
        $insertPos.before($insertPos.depth)
      ) : $insertPos.pos;
      return setSelection(content, pos, tr);
    }
  }
  if (canInsert($insertPos, content)) {
    tr.insert($insertPos.pos, content);
    const pos = hasPosition ? $insertPos.pos : isSelectableNode(content) ? (
      // for atom nodes selection position after insertion is the previous pos
      tr.selection.$anchor.pos - 1
    ) : tr.selection.$anchor.pos;
    return cloneTr(setSelection(content, pos, tr));
  }
  for (let i = $insertPos.depth; i > 0; i--) {
    const pos = $insertPos.after(i);
    const $pos = tr.doc.resolve(pos);
    if (canInsert($pos, content)) {
      tr.insert(pos, content);
      return cloneTr(setSelection(content, pos, tr));
    }
  }
  return tr;
};
var setParentNodeMarkup = (nodeType, type, attrs, marks) => (tr) => {
  const parent = findParentNodeOfType(nodeType)(tr.selection);
  if (parent) {
    return cloneTr(
      tr.setNodeMarkup(
        parent.pos,
        type,
        Object.assign({}, parent.node.attrs, attrs),
        marks
      )
    );
  }
  return tr;
};
var selectParentNodeOfType = (nodeType) => (tr) => {
  if (!isNodeSelection(tr.selection)) {
    const parent = findParentNodeOfType(nodeType)(tr.selection);
    if (parent) {
      return cloneTr(
        tr.setSelection(NodeSelection.create(tr.doc, parent.pos))
      );
    }
  }
  return tr;
};
var removeNodeBefore = (tr) => {
  const position = findPositionOfNodeBefore(tr.selection);
  if (typeof position === "number") {
    return removeNodeAtPos(position)(tr);
  }
  return tr;
};

// src/helpers.ts
var isNodeSelection = (selection) => {
  return selection instanceof NodeSelection2;
};
var equalNodeType = (nodeType, node) => {
  return Array.isArray(nodeType) && nodeType.indexOf(node.type) > -1 || node.type === nodeType;
};
var cloneTr = (tr) => {
  return Object.assign(Object.create(tr), tr).setTime(Date.now());
};
var replaceNodeAtPos = (position, content) => (tr) => {
  const node = tr.doc.nodeAt(position);
  const $pos = tr.doc.resolve(position);
  if (!node) {
    return tr;
  }
  if (canReplace($pos, content)) {
    tr = tr.replaceWith(position, position + node.nodeSize, content);
    const start = tr.selection.$from.pos - 1;
    tr = setTextSelection(Math.max(start, 0), -1)(tr);
    tr = setTextSelection(tr.selection.$from.start())(tr);
    return cloneTr(tr);
  }
  return tr;
};
var canReplace = ($pos, content) => {
  const node = $pos.node($pos.depth);
  return node && node.type.validContent(
    content instanceof Fragment2 ? content : Fragment2.from(content)
  );
};
var removeNodeAtPos = (position) => (tr) => {
  const node = tr.doc.nodeAt(position);
  if (!node) {
    return tr;
  }
  return cloneTr(tr.delete(position, position + node.nodeSize));
};
var canInsert = ($pos, content) => {
  const index = $pos.index();
  if (content instanceof Fragment2) {
    return $pos.parent.canReplace(index, index, content);
  } else if (content instanceof PMNode2) {
    return $pos.parent.canReplaceWith(index, index, content.type);
  }
  return false;
};
var isEmptyParagraph = (node) => {
  return !node || node.type.name === "paragraph" && node.nodeSize === 2;
};

// src/selection.ts
var findParentNode = (predicate) => ({ $from, $to }, validateSameParent = false) => {
  if (validateSameParent && !$from.sameParent($to)) {
    let depth = Math.min($from.depth, $to.depth);
    while (depth >= 0) {
      const fromNode = $from.node(depth);
      const toNode = $to.node(depth);
      if (toNode === fromNode) {
        if (predicate(fromNode)) {
          return {
            // Return the resolved pos
            pos: depth > 0 ? $from.before(depth) : 0,
            start: $from.start(depth),
            depth,
            node: fromNode
          };
        }
      }
      depth = depth - 1;
    }
    return;
  }
  return findParentNodeClosestToPos($from, predicate);
};
var findParentNodeClosestToPos = ($pos, predicate) => {
  for (let i = $pos.depth; i > 0; i--) {
    const node = $pos.node(i);
    if (predicate(node)) {
      return {
        pos: i > 0 ? $pos.before(i) : 0,
        start: $pos.start(i),
        depth: i,
        node
      };
    }
  }
};
var findParentDomRef = (predicate, domAtPos) => (selection) => {
  const parent = findParentNode(predicate)(selection);
  if (parent) {
    return findDomRefAtPos(parent.pos, domAtPos);
  }
};
var hasParentNode = (predicate) => (selection) => {
  return !!findParentNode(predicate)(selection);
};
var findParentNodeOfType = (nodeType) => (selection) => {
  return findParentNode((node) => equalNodeType(nodeType, node))(selection);
};
var findParentNodeOfTypeClosestToPos = ($pos, nodeType) => {
  return findParentNodeClosestToPos(
    $pos,
    (node) => equalNodeType(nodeType, node)
  );
};
var hasParentNodeOfType = (nodeType) => (selection) => {
  return hasParentNode((node) => equalNodeType(nodeType, node))(selection);
};
var findParentDomRefOfType = (nodeType, domAtPos) => (selection) => {
  return findParentDomRef(
    (node) => equalNodeType(nodeType, node),
    domAtPos
  )(selection);
};
var findSelectedNodeOfType = (nodeType) => (selection) => {
  if (isNodeSelection(selection)) {
    const { node, $from } = selection;
    if (equalNodeType(nodeType, node)) {
      return {
        node,
        start: $from.start(),
        pos: $from.pos,
        depth: $from.depth
      };
    }
  }
};
var findPositionOfNodeBefore = (selection) => {
  const { nodeBefore } = selection.$from;
  const maybeSelection = Selection3.findFrom(selection.$from, -1);
  if (maybeSelection && nodeBefore) {
    const parent = findParentNodeOfType(nodeBefore.type)(maybeSelection);
    if (parent) {
      return parent.pos;
    }
    return maybeSelection.$from.pos;
  }
};
var findDomRefAtPos = (position, domAtPos) => {
  const dom = domAtPos(position);
  const node = dom.node.childNodes[dom.offset];
  if (dom.node.nodeType === Node.TEXT_NODE && dom.node.parentNode) {
    return dom.node.parentNode;
  }
  if (!node || node.nodeType === Node.TEXT_NODE) {
    return dom.node;
  }
  return node;
};

// src/node.ts
var flatten = (node, descend = true) => {
  if (!node) {
    throw new Error('Invalid "node" parameter');
  }
  const result = [];
  node.descendants((child, pos) => {
    result.push({ node: child, pos });
    if (!descend) {
      return false;
    }
  });
  return result;
};
var findChildren = (node, predicate, descend = true) => {
  if (!node) {
    throw new Error('Invalid "node" parameter');
  } else if (!predicate) {
    throw new Error('Invalid "predicate" parameter');
  }
  return flatten(node, descend).filter((child) => predicate(child.node));
};
var findTextNodes = (node, descend = true) => {
  return findChildren(node, (child) => child.isText, descend);
};
var findInlineNodes = (node, descend = true) => {
  return findChildren(node, (child) => child.isInline, descend);
};
var findBlockNodes = (node, descend = true) => {
  return findChildren(node, (child) => child.isBlock, descend);
};
var findChildrenByAttr = (node, predicate, descend = true) => {
  return findChildren(node, (child) => !!predicate(child.attrs), descend);
};
var findChildrenByType = (node, nodeType, descend = true) => {
  return findChildren(node, (child) => child.type === nodeType, descend);
};
var findChildrenByMark = (node, markType, descend = true) => {
  return findChildren(
    node,
    (child) => Boolean(markType.isInSet(child.marks)),
    descend
  );
};
var contains = (node, nodeType) => {
  return !!findChildrenByType(node, nodeType).length;
};
export {
  canInsert,
  contains,
  findBlockNodes,
  findChildren,
  findChildrenByAttr,
  findChildrenByMark,
  findChildrenByType,
  findDomRefAtPos,
  findInlineNodes,
  findParentDomRef,
  findParentDomRefOfType,
  findParentNode,
  findParentNodeClosestToPos,
  findParentNodeOfType,
  findParentNodeOfTypeClosestToPos,
  findPositionOfNodeBefore,
  findSelectedNodeOfType,
  findTextNodes,
  flatten,
  hasParentNode,
  hasParentNodeOfType,
  isNodeSelection,
  removeNodeBefore,
  removeParentNodeOfType,
  removeSelectedNode,
  replaceParentNodeOfType,
  replaceSelectedNode,
  safeInsert,
  selectParentNodeOfType,
  setParentNodeMarkup,
  setTextSelection
};
//# sourceMappingURL=index.esm.js.map
