import {Slice, Fragment, NodeRange, NodeType, Node, Mark, Attrs, ContentMatch} from "prosemirror-model"

import {Transform} from "./transform"
import {ReplaceStep, ReplaceAroundStep} from "./replace_step"
import {clearIncompatible} from "./mark"

function canCut(node: Node, start: number, end: number) {
  return (start == 0 || node.canReplace(start, node.childCount)) &&
    (end == node.childCount || node.canReplace(0, end))
}

/// Try to find a target depth to which the content in the given range
/// can be lifted. Will not go across
/// [isolating](#model.NodeSpec.isolating) parent nodes.
export function liftTarget(range: NodeRange): number | null {
  let parent = range.parent
  let content = parent.content.cutByIndex(range.startIndex, range.endIndex)
  for (let depth = range.depth;; --depth) {
    let node = range.$from.node(depth)
    let index = range.$from.index(depth), endIndex = range.$to.indexAfter(depth)
    if (depth < range.depth && node.canReplace(index, endIndex, content))
      return depth
    if (depth == 0 || node.type.spec.isolating || !canCut(node, index, endIndex)) break
  }
  return null
}

export function lift(tr: Transform, range: NodeRange, target: number) {
  let {$from, $to, depth} = range

  let gapStart = $from.before(depth + 1), gapEnd = $to.after(depth + 1)
  let start = gapStart, end = gapEnd

  let before = Fragment.empty, openStart = 0
  for (let d = depth, splitting = false; d > target; d--)
    if (splitting || $from.index(d) > 0) {
      splitting = true
      before = Fragment.from($from.node(d).copy(before))
      openStart++
    } else {
      start--
    }
  let after = Fragment.empty, openEnd = 0
  for (let d = depth, splitting = false; d > target; d--)
    if (splitting || $to.after(d + 1) < $to.end(d)) {
      splitting = true
      after = Fragment.from($to.node(d).copy(after))
      openEnd++
    } else {
      end++
    }

  tr.step(new ReplaceAroundStep(start, end, gapStart, gapEnd,
                                new Slice(before.append(after), openStart, openEnd),
                                before.size - openStart, true))
}

/// Try to find a valid way to wrap the content in the given range in a
/// node of the given type. May introduce extra nodes around and inside
/// the wrapper node, if necessary. Returns null if no valid wrapping
/// could be found. When `innerRange` is given, that range's content is
/// used as the content to fit into the wrapping, instead of the
/// content of `range`.
export function findWrapping(
  range: NodeRange,
  nodeType: NodeType,
  attrs: Attrs | null = null,
  innerRange = range
): {type: NodeType, attrs: Attrs | null}[] | null {
  let around = findWrappingOutside(range, nodeType)
  let inner = around && findWrappingInside(innerRange, nodeType)
  if (!inner) return null
  return (around!.map(withAttrs) as {type: NodeType, attrs: Attrs | null}[])
    .concat({type: nodeType, attrs}).concat(inner.map(withAttrs))
}

function withAttrs(type: NodeType) { return {type, attrs: null} }

function findWrappingOutside(range: NodeRange, type: NodeType) {
  let {parent, startIndex, endIndex} = range
  let around = parent.contentMatchAt(startIndex).findWrapping(type)
  if (!around) return null
  let outer = around.length ? around[0] : type
  return parent.canReplaceWith(startIndex, endIndex, outer) ? around : null
}

function findWrappingInside(range: NodeRange, type: NodeType) {
  let {parent, startIndex, endIndex} = range
  let inner = parent.child(startIndex)
  let inside = type.contentMatch.findWrapping(inner.type)
  if (!inside) return null
  let lastType = inside.length ? inside[inside.length - 1] : type
  let innerMatch: ContentMatch | null = lastType.contentMatch
  for (let i = startIndex; innerMatch && i < endIndex; i++)
    innerMatch = innerMatch.matchType(parent.child(i).type)
  if (!innerMatch || !innerMatch.validEnd) return null
  return inside
}

export function wrap(tr: Transform, range: NodeRange, wrappers: readonly {type: NodeType, attrs?: Attrs | null}[]) {
  let content = Fragment.empty
  for (let i = wrappers.length - 1; i >= 0; i--) {
    if (content.size) {
      let match = wrappers[i].type.contentMatch.matchFragment(content)
      if (!match || !match.validEnd)
        throw new RangeError("Wrapper type given to Transform.wrap does not form valid content of its parent wrapper")
    }
    content = Fragment.from(wrappers[i].type.create(wrappers[i].attrs, content))
  }

  let start = range.start, end = range.end
  tr.step(new ReplaceAroundStep(start, end, start, end, new Slice(content, 0, 0), wrappers.length, true))
}

export function setBlockType(tr: Transform, from: number, to: number,
                             type: NodeType, attrs: Attrs | null | ((oldNode: Node) => Attrs)) {
  if (!type.isTextblock) throw new RangeError("Type given to setBlockType should be a textblock")
  let mapFrom = tr.steps.length
  tr.doc.nodesBetween(from, to, (node, pos) => {
    let attrsHere = typeof attrs == "function" ? attrs(node) : attrs
    if (node.isTextblock && !node.hasMarkup(type, attrsHere) &&
        canChangeType(tr.doc, tr.mapping.slice(mapFrom).map(pos), type)) {
      let convertNewlines = null
      if (type.schema.linebreakReplacement) {
        let pre = type.whitespace == "pre", supportLinebreak = !!type.contentMatch.matchType(type.schema.linebreakReplacement)
        if (pre && !supportLinebreak) convertNewlines = false
        else if (!pre && supportLinebreak) convertNewlines = true
      }
      // Ensure all markup that isn't allowed in the new node type is cleared
      if (convertNewlines === false) replaceLinebreaks(tr, node, pos, mapFrom)
      clearIncompatible(tr, tr.mapping.slice(mapFrom).map(pos, 1), type, undefined, convertNewlines === null)
      let mapping = tr.mapping.slice(mapFrom)
      let startM = mapping.map(pos, 1), endM = mapping.map(pos + node.nodeSize, 1)
      tr.step(new ReplaceAroundStep(startM, endM, startM + 1, endM - 1,
                                      new Slice(Fragment.from(type.create(attrsHere, null, node.marks)), 0, 0), 1, true))
      if (convertNewlines === true) replaceNewlines(tr, node, pos, mapFrom)
      return false
    }
  })
}

function replaceNewlines(tr: Transform, node: Node, pos: number, mapFrom: number) {
  node.forEach((child, offset) => {
    if (child.isText) {
      let m, newline = /\r?\n|\r/g
      while (m = newline.exec(child.text!)) {
        let start = tr.mapping.slice(mapFrom).map(pos + 1 + offset + m.index)
        tr.replaceWith(start, start + 1, node.type.schema.linebreakReplacement!.create())
      }
    }
  })
}

function replaceLinebreaks(tr: Transform, node: Node, pos: number, mapFrom: number) {
  node.forEach((child, offset) => {
    if (child.type == child.type.schema.linebreakReplacement) {
      let start = tr.mapping.slice(mapFrom).map(pos + 1 + offset)
      tr.replaceWith(start, start + 1, node.type.schema.text("\n"))
    }
  })
}

function canChangeType(doc: Node, pos: number, type: NodeType) {
  let $pos = doc.resolve(pos), index = $pos.index()
  return $pos.parent.canReplaceWith(index, index + 1, type)
}

/// Change the type, attributes, and/or marks of the node at `pos`.
/// When `type` isn't given, the existing node type is preserved,
export function setNodeMarkup(tr: Transform, pos: number, type: NodeType | undefined | null,
                              attrs: Attrs | null, marks: readonly Mark[] | undefined) {
  let node = tr.doc.nodeAt(pos)
  if (!node) throw new RangeError("No node at given position")
  if (!type) type = node.type
  let newNode = type.create(attrs, null, marks || node.marks)
  if (node.isLeaf)
    return tr.replaceWith(pos, pos + node.nodeSize, newNode)

  if (!type.validContent(node.content))
    throw new RangeError("Invalid content for node type " + type.name)

  tr.step(new ReplaceAroundStep(pos, pos + node.nodeSize, pos + 1, pos + node.nodeSize - 1,
                                new Slice(Fragment.from(newNode), 0, 0), 1, true))
}

/// Check whether splitting at the given position is allowed.
export function canSplit(doc: Node, pos: number, depth = 1,
                         typesAfter?: (null | {type: NodeType, attrs?: Attrs | null})[]): boolean {
  let $pos = doc.resolve(pos), base = $pos.depth - depth
  let innerType = (typesAfter && typesAfter[typesAfter.length - 1]) || $pos.parent
  if (base < 0 || $pos.parent.type.spec.isolating ||
      !$pos.parent.canReplace($pos.index(), $pos.parent.childCount) ||
      !innerType.type.validContent($pos.parent.content.cutByIndex($pos.index(), $pos.parent.childCount)))
    return false
  for (let d = $pos.depth - 1, i = depth - 2; d > base; d--, i--) {
    let node = $pos.node(d), index = $pos.index(d)
    if (node.type.spec.isolating) return false
    let rest = node.content.cutByIndex(index, node.childCount)
    let overrideChild = typesAfter && typesAfter[i + 1]
    if (overrideChild)
      rest = rest.replaceChild(0, overrideChild.type.create(overrideChild.attrs))
    let after = (typesAfter && typesAfter[i]) || node
    if (!node.canReplace(index + 1, node.childCount) || !after.type.validContent(rest))
      return false
  }
  let index = $pos.indexAfter(base)
  let baseType = typesAfter && typesAfter[0]
  return $pos.node(base).canReplaceWith(index, index, baseType ? baseType.type : $pos.node(base + 1).type)
}

export function split(tr: Transform, pos: number, depth = 1, typesAfter?: (null | {type: NodeType, attrs?: Attrs | null})[]) {
  let $pos = tr.doc.resolve(pos), before = Fragment.empty, after = Fragment.empty
  for (let d = $pos.depth, e = $pos.depth - depth, i = depth - 1; d > e; d--, i--) {
    before = Fragment.from($pos.node(d).copy(before))
    let typeAfter = typesAfter && typesAfter[i]
    after = Fragment.from(typeAfter ? typeAfter.type.create(typeAfter.attrs, after) : $pos.node(d).copy(after))
  }
  tr.step(new ReplaceStep(pos, pos, new Slice(before.append(after), depth, depth), true))
}

/// Test whether the blocks before and after a given position can be
/// joined.
export function canJoin(doc: Node, pos: number): boolean {
  let $pos = doc.resolve(pos), index = $pos.index()
  return joinable($pos.nodeBefore, $pos.nodeAfter) &&
    $pos.parent.canReplace(index, index + 1)
}

function joinable(a: Node | null, b: Node | null) {
  return !!(a && b && !a.isLeaf && a.canAppend(b))
}

/// Find an ancestor of the given position that can be joined to the
/// block before (or after if `dir` is positive). Returns the joinable
/// point, if any.
export function joinPoint(doc: Node, pos: number, dir = -1) {
  let $pos = doc.resolve(pos)
  for (let d = $pos.depth;; d--) {
    let before, after, index = $pos.index(d)
    if (d == $pos.depth) {
      before = $pos.nodeBefore
      after = $pos.nodeAfter
    } else if (dir > 0) {
      before = $pos.node(d + 1)
      index++
      after = $pos.node(d).maybeChild(index)
    } else {
      before = $pos.node(d).maybeChild(index - 1)
      after = $pos.node(d + 1)
    }
    if (before && !before.isTextblock && joinable(before, after) &&
        $pos.node(d).canReplace(index, index + 1)) return pos
    if (d == 0) break
    pos = dir < 0 ? $pos.before(d) : $pos.after(d)
  }
}

export function join(tr: Transform, pos: number, depth: number) {
  let step = new ReplaceStep(pos - depth, pos + depth, Slice.empty, true)
  tr.step(step)
}

/// Try to find a point where a node of the given type can be inserted
/// near `pos`, by searching up the node hierarchy when `pos` itself
/// isn't a valid place but is at the start or end of a node. Return
/// null if no position was found.
export function insertPoint(doc: Node, pos: number, nodeType: NodeType): number | null {
  let $pos = doc.resolve(pos)
  if ($pos.parent.canReplaceWith($pos.index(), $pos.index(), nodeType)) return pos

  if ($pos.parentOffset == 0)
    for (let d = $pos.depth - 1; d >= 0; d--) {
      let index = $pos.index(d)
      if ($pos.node(d).canReplaceWith(index, index, nodeType)) return $pos.before(d + 1)
      if (index > 0) return null
    }
  if ($pos.parentOffset == $pos.parent.content.size)
    for (let d = $pos.depth - 1; d >= 0; d--) {
      let index = $pos.indexAfter(d)
      if ($pos.node(d).canReplaceWith(index, index, nodeType)) return $pos.after(d + 1)
      if (index < $pos.node(d).childCount) return null
    }
  return null
}

/// Finds a position at or around the given position where the given
/// slice can be inserted. Will look at parent nodes' nearest boundary
/// and try there, even if the original position wasn't directly at the
/// start or end of that node. Returns null when no position was found.
export function dropPoint(doc: Node, pos: number, slice: Slice): number | null {
  let $pos = doc.resolve(pos)
  if (!slice.content.size) return pos
  let content = slice.content
  for (let i = 0; i < slice.openStart; i++) content = content.firstChild!.content
  for (let pass = 1; pass <= (slice.openStart == 0 && slice.size ? 2 : 1); pass++) {
    for (let d = $pos.depth; d >= 0; d--) {
      let bias = d == $pos.depth ? 0 : $pos.pos <= ($pos.start(d + 1) + $pos.end(d + 1)) / 2 ? -1 : 1
      let insertPos = $pos.index(d) + (bias > 0 ? 1 : 0)
      let parent = $pos.node(d), fits: boolean | null = false
      if (pass == 1) {
        fits = parent.canReplace(insertPos, insertPos, content)
      } else {
        let wrapping = parent.contentMatchAt(insertPos).findWrapping(content.firstChild!.type)
        fits = wrapping && parent.canReplaceWith(insertPos, insertPos, wrapping[0])
      }
      if (fits)
        return bias == 0 ? $pos.pos : bias < 0 ? $pos.before(d + 1) : $pos.after(d + 1)
    }
  }
  return null
}
