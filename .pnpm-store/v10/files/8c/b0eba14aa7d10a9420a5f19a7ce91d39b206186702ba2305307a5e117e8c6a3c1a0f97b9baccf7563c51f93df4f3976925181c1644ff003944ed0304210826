import {Fragment} from "./fragment"
import {Schema} from "./schema"
import {Node, TextNode} from "./node"
import {ResolvedPos} from "./resolvedpos"

/// Error type raised by [`Node.replace`](#model.Node.replace) when
/// given an invalid replacement.
export class ReplaceError extends Error {}
/*
ReplaceError = function(this: any, message: string) {
  let err = Error.call(this, message)
  ;(err as any).__proto__ = ReplaceError.prototype
  return err
} as any

ReplaceError.prototype = Object.create(Error.prototype)
ReplaceError.prototype.constructor = ReplaceError
ReplaceError.prototype.name = "ReplaceError"
*/

/// A slice represents a piece cut out of a larger document. It
/// stores not only a fragment, but also the depth up to which nodes on
/// both side are ‘open’ (cut through).
export class Slice {
  /// Create a slice. When specifying a non-zero open depth, you must
  /// make sure that there are nodes of at least that depth at the
  /// appropriate side of the fragment—i.e. if the fragment is an
  /// empty paragraph node, `openStart` and `openEnd` can't be greater
  /// than 1.
  ///
  /// It is not necessary for the content of open nodes to conform to
  /// the schema's content constraints, though it should be a valid
  /// start/end/middle for such a node, depending on which sides are
  /// open.
  constructor(
    /// The slice's content.
    readonly content: Fragment,
    /// The open depth at the start of the fragment.
    readonly openStart: number,
    /// The open depth at the end.
    readonly openEnd: number
  ) {}

  /// The size this slice would add when inserted into a document.
  get size(): number {
    return this.content.size - this.openStart - this.openEnd
  }

  /// @internal
  insertAt(pos: number, fragment: Fragment) {
    let content = insertInto(this.content, pos + this.openStart, fragment)
    return content && new Slice(content, this.openStart, this.openEnd)
  }

  /// @internal
  removeBetween(from: number, to: number) {
    return new Slice(removeRange(this.content, from + this.openStart, to + this.openStart), this.openStart, this.openEnd)
  }

  /// Tests whether this slice is equal to another slice.
  eq(other: Slice): boolean {
    return this.content.eq(other.content) && this.openStart == other.openStart && this.openEnd == other.openEnd
  }

  /// @internal
  toString() {
    return this.content + "(" + this.openStart + "," + this.openEnd + ")"
  }

  /// Convert a slice to a JSON-serializable representation.
  toJSON(): any {
    if (!this.content.size) return null
    let json: any = {content: this.content.toJSON()}
    if (this.openStart > 0) json.openStart = this.openStart
    if (this.openEnd > 0) json.openEnd = this.openEnd
    return json
  }

  /// Deserialize a slice from its JSON representation.
  static fromJSON(schema: Schema, json: any): Slice {
    if (!json) return Slice.empty
    let openStart = json.openStart || 0, openEnd = json.openEnd || 0
    if (typeof openStart != "number" || typeof openEnd != "number")
      throw new RangeError("Invalid input for Slice.fromJSON")
    return new Slice(Fragment.fromJSON(schema, json.content), openStart, openEnd)
  }

  /// Create a slice from a fragment by taking the maximum possible
  /// open value on both side of the fragment.
  static maxOpen(fragment: Fragment, openIsolating = true) {
    let openStart = 0, openEnd = 0
    for (let n = fragment.firstChild; n && !n.isLeaf && (openIsolating || !n.type.spec.isolating); n = n.firstChild) openStart++
    for (let n = fragment.lastChild; n && !n.isLeaf && (openIsolating || !n.type.spec.isolating); n = n.lastChild) openEnd++
    return new Slice(fragment, openStart, openEnd)
  }

  /// The empty slice.
  static empty = new Slice(Fragment.empty, 0, 0)
}

function removeRange(content: Fragment, from: number, to: number): Fragment {
  let {index, offset} = content.findIndex(from), child = content.maybeChild(index)
  let {index: indexTo, offset: offsetTo} = content.findIndex(to)
  if (offset == from || child!.isText) {
    if (offsetTo != to && !content.child(indexTo).isText) throw new RangeError("Removing non-flat range")
    return content.cut(0, from).append(content.cut(to))
  }
  if (index != indexTo) throw new RangeError("Removing non-flat range")
  return content.replaceChild(index, child!.copy(removeRange(child!.content, from - offset - 1, to - offset - 1)))
}

function insertInto(content: Fragment, dist: number, insert: Fragment, parent?: Node): Fragment | null {
  let {index, offset} = content.findIndex(dist), child = content.maybeChild(index)
  if (offset == dist || child!.isText) {
    if (parent && !parent.canReplace(index, index, insert)) return null
    return content.cut(0, dist).append(insert).append(content.cut(dist))
  }
  let inner = insertInto(child!.content, dist - offset - 1, insert)
  return inner && content.replaceChild(index, child!.copy(inner))
}

export function replace($from: ResolvedPos, $to: ResolvedPos, slice: Slice) {
  if (slice.openStart > $from.depth)
    throw new ReplaceError("Inserted content deeper than insertion position")
  if ($from.depth - slice.openStart != $to.depth - slice.openEnd)
    throw new ReplaceError("Inconsistent open depths")
  return replaceOuter($from, $to, slice, 0)
}

function replaceOuter($from: ResolvedPos, $to: ResolvedPos, slice: Slice, depth: number): Node {
  let index = $from.index(depth), node = $from.node(depth)
  if (index == $to.index(depth) && depth < $from.depth - slice.openStart) {
    let inner = replaceOuter($from, $to, slice, depth + 1)
    return node.copy(node.content.replaceChild(index, inner))
  } else if (!slice.content.size) {
    return close(node, replaceTwoWay($from, $to, depth))
  } else if (!slice.openStart && !slice.openEnd && $from.depth == depth && $to.depth == depth) { // Simple, flat case
    let parent = $from.parent, content = parent.content
    return close(parent, content.cut(0, $from.parentOffset).append(slice.content).append(content.cut($to.parentOffset)))
  } else {
    let {start, end} = prepareSliceForReplace(slice, $from)
    return close(node, replaceThreeWay($from, start, end, $to, depth))
  }
}

function checkJoin(main: Node, sub: Node) {
  if (!sub.type.compatibleContent(main.type))
    throw new ReplaceError("Cannot join " + sub.type.name + " onto " + main.type.name)
}

function joinable($before: ResolvedPos, $after: ResolvedPos, depth: number) {
  let node = $before.node(depth)
  checkJoin(node, $after.node(depth))
  return node
}

function addNode(child: Node, target: Node[]) {
  let last = target.length - 1
  if (last >= 0 && child.isText && child.sameMarkup(target[last]))
    target[last] = (child as TextNode).withText(target[last].text! + child.text!)
  else
    target.push(child)
}

function addRange($start: ResolvedPos | null, $end: ResolvedPos | null, depth: number, target: Node[]) {
  let node = ($end || $start)!.node(depth)
  let startIndex = 0, endIndex = $end ? $end.index(depth) : node.childCount
  if ($start) {
    startIndex = $start.index(depth)
    if ($start.depth > depth) {
      startIndex++
    } else if ($start.textOffset) {
      addNode($start.nodeAfter!, target)
      startIndex++
    }
  }
  for (let i = startIndex; i < endIndex; i++) addNode(node.child(i), target)
  if ($end && $end.depth == depth && $end.textOffset)
    addNode($end.nodeBefore!, target)
}

function close(node: Node, content: Fragment) {
  node.type.checkContent(content)
  return node.copy(content)
}

function replaceThreeWay($from: ResolvedPos, $start: ResolvedPos, $end: ResolvedPos, $to: ResolvedPos, depth: number) {
  let openStart = $from.depth > depth && joinable($from, $start, depth + 1)
  let openEnd = $to.depth > depth && joinable($end, $to, depth + 1)

  let content: Node[] = []
  addRange(null, $from, depth, content)
  if (openStart && openEnd && $start.index(depth) == $end.index(depth)) {
    checkJoin(openStart, openEnd)
    addNode(close(openStart, replaceThreeWay($from, $start, $end, $to, depth + 1)), content)
  } else {
    if (openStart)
      addNode(close(openStart, replaceTwoWay($from, $start, depth + 1)), content)
    addRange($start, $end, depth, content)
    if (openEnd)
      addNode(close(openEnd, replaceTwoWay($end, $to, depth + 1)), content)
  }
  addRange($to, null, depth, content)
  return new Fragment(content)
}

function replaceTwoWay($from: ResolvedPos, $to: ResolvedPos, depth: number) {
  let content: Node[] = []
  addRange(null, $from, depth, content)
  if ($from.depth > depth) {
    let type = joinable($from, $to, depth + 1)
    addNode(close(type, replaceTwoWay($from, $to, depth + 1)), content)
  }
  addRange($to, null, depth, content)
  return new Fragment(content)
}

function prepareSliceForReplace(slice: Slice, $along: ResolvedPos) {
  let extra = $along.depth - slice.openStart, parent = $along.node(extra)
  let node = parent.copy(slice.content)
  for (let i = extra - 1; i >= 0; i--)
    node = $along.node(i).copy(Fragment.from(node))
  return {start: node.resolveNoCache(slice.openStart + extra),
          end: node.resolveNoCache(node.content.size - slice.openEnd - extra)}
}
