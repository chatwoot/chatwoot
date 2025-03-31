import {Node, Mark} from "prosemirror-model"
import {Mappable, Mapping} from "prosemirror-transform"
import {EditorView} from "./index"
import {DOMNode} from "./dom"

function compareObjs(a: {[prop: string]: any}, b: {[prop: string]: any}) {
  if (a == b) return true
  for (let p in a) if (a[p] !== b[p]) return false
  for (let p in b) if (!(p in a)) return false
  return true
}

export interface DecorationType {
  spec: any
  map(mapping: Mappable, span: Decoration, offset: number, oldOffset: number): Decoration | null
  valid(node: Node, span: Decoration): boolean
  eq(other: DecorationType): boolean
  destroy(dom: DOMNode): void
}

export type WidgetConstructor = ((view: EditorView, getPos: () => number | undefined) => DOMNode) | DOMNode

export class WidgetType implements DecorationType {
  spec: any
  side: number

  constructor(readonly toDOM: WidgetConstructor, spec: any) {
    this.spec = spec || noSpec
    this.side = this.spec.side || 0
  }

  map(mapping: Mappable, span: Decoration, offset: number, oldOffset: number): Decoration | null {
    let {pos, deleted} = mapping.mapResult(span.from + oldOffset, this.side < 0 ? -1 : 1)
    return deleted ? null : new Decoration(pos - offset, pos - offset, this)
  }

  valid() { return true }

  eq(other: WidgetType) {
    return this == other ||
      (other instanceof WidgetType &&
       (this.spec.key && this.spec.key == other.spec.key ||
        this.toDOM == other.toDOM && compareObjs(this.spec, other.spec)))
  }

  destroy(node: DOMNode) {
    if (this.spec.destroy) this.spec.destroy(node)
  }
}

export class InlineType implements DecorationType {
  spec: any

  constructor(readonly attrs: DecorationAttrs, spec: any) {
    this.spec = spec || noSpec
  }

  map(mapping: Mappable, span: Decoration, offset: number, oldOffset: number): Decoration | null {
    let from = mapping.map(span.from + oldOffset, this.spec.inclusiveStart ? -1 : 1) - offset
    let to = mapping.map(span.to + oldOffset, this.spec.inclusiveEnd ? 1 : -1) - offset
    return from >= to ? null : new Decoration(from, to, this)
  }

  valid(_: Node, span: Decoration) { return span.from < span.to }

  eq(other: DecorationType): boolean {
    return this == other ||
      (other instanceof InlineType && compareObjs(this.attrs, other.attrs) &&
       compareObjs(this.spec, other.spec))
  }

  static is(span: Decoration) { return span.type instanceof InlineType }

  destroy() {}
}

export class NodeType implements DecorationType {
  spec: any
  constructor(readonly attrs: DecorationAttrs, spec: any) {
    this.spec = spec || noSpec
  }

  map(mapping: Mappable, span: Decoration, offset: number, oldOffset: number): Decoration | null {
    let from = mapping.mapResult(span.from + oldOffset, 1)
    if (from.deleted) return null
    let to = mapping.mapResult(span.to + oldOffset, -1)
    if (to.deleted || to.pos <= from.pos) return null
    return new Decoration(from.pos - offset, to.pos - offset, this)
  }

  valid(node: Node, span: Decoration): boolean {
    let {index, offset} = node.content.findIndex(span.from), child
    return offset == span.from && !(child = node.child(index)).isText && offset + child.nodeSize == span.to
  }

  eq(other: DecorationType): boolean {
    return this == other ||
      (other instanceof NodeType && compareObjs(this.attrs, other.attrs) &&
       compareObjs(this.spec, other.spec))
  }

  destroy() {}
}

/// Decoration objects can be provided to the view through the
/// [`decorations` prop](#view.EditorProps.decorations). They come in
/// several variants—see the static members of this class for details.
export class Decoration {
  /// @internal
  constructor(
    /// The start position of the decoration.
    readonly from: number,
    /// The end position. Will be the same as `from` for [widget
    /// decorations](#view.Decoration^widget).
    readonly to: number,
    /// @internal
    readonly type: DecorationType
  ) {}

  /// @internal
  copy(from: number, to: number) {
    return new Decoration(from, to, this.type)
  }

  /// @internal
  eq(other: Decoration, offset = 0) {
    return this.type.eq(other.type) && this.from + offset == other.from && this.to + offset == other.to
  }

  /// @internal
  map(mapping: Mappable, offset: number, oldOffset: number) {
    return this.type.map(mapping, this, offset, oldOffset)
  }

  /// Creates a widget decoration, which is a DOM node that's shown in
  /// the document at the given position. It is recommended that you
  /// delay rendering the widget by passing a function that will be
  /// called when the widget is actually drawn in a view, but you can
  /// also directly pass a DOM node. `getPos` can be used to find the
  /// widget's current document position.
  static widget(pos: number, toDOM: WidgetConstructor, spec?: {
    /// Controls which side of the document position this widget is
    /// associated with. When negative, it is drawn before a cursor
    /// at its position, and content inserted at that position ends
    /// up after the widget. When zero (the default) or positive, the
    /// widget is drawn after the cursor and content inserted there
    /// ends up before the widget.
    ///
    /// When there are multiple widgets at a given position, their
    /// `side` values determine the order in which they appear. Those
    /// with lower values appear first. The ordering of widgets with
    /// the same `side` value is unspecified.
    ///
    /// When `marks` is null, `side` also determines the marks that
    /// the widget is wrapped in—those of the node before when
    /// negative, those of the node after when positive.
    side?: number

    /// The precise set of marks to draw around the widget.
    marks?: readonly Mark[]

    /// Can be used to control which DOM events, when they bubble out
    /// of this widget, the editor view should ignore.
    stopEvent?: (event: Event) => boolean

    /// When set (defaults to false), selection changes inside the
    /// widget are ignored, and don't cause ProseMirror to try and
    /// re-sync the selection with its selection state.
    ignoreSelection?: boolean

    /// When comparing decorations of this type (in order to decide
    /// whether it needs to be redrawn), ProseMirror will by default
    /// compare the widget DOM node by identity. If you pass a key,
    /// that key will be compared instead, which can be useful when
    /// you generate decorations on the fly and don't want to store
    /// and reuse DOM nodes. Make sure that any widgets with the same
    /// key are interchangeable—if widgets differ in, for example,
    /// the behavior of some event handler, they should get
    /// different keys.
    key?: string

    /// Called when the widget decoration is removed or the editor is
    /// destroyed.
    destroy?: (node: DOMNode) => void

    /// Specs allow arbitrary additional properties.
    [key: string]: any
  }): Decoration {
    return new Decoration(pos, pos, new WidgetType(toDOM, spec))
  }

  /// Creates an inline decoration, which adds the given attributes to
  /// each inline node between `from` and `to`.
  static inline(from: number, to: number, attrs: DecorationAttrs, spec?: {
    /// Determines how the left side of the decoration is
    /// [mapped](#transform.Position_Mapping) when content is
    /// inserted directly at that position. By default, the decoration
    /// won't include the new content, but you can set this to `true`
    /// to make it inclusive.
    inclusiveStart?: boolean

    /// Determines how the right side of the decoration is mapped.
    /// See
    /// [`inclusiveStart`](#view.Decoration^inline^spec.inclusiveStart).
    inclusiveEnd?: boolean

    /// Specs may have arbitrary additional properties.
    [key: string]: any
  }) {
    return new Decoration(from, to, new InlineType(attrs, spec))
  }

  /// Creates a node decoration. `from` and `to` should point precisely
  /// before and after a node in the document. That node, and only that
  /// node, will receive the given attributes.
  static node(from: number, to: number, attrs: DecorationAttrs, spec?: any) {
    return new Decoration(from, to, new NodeType(attrs, spec))
  }

  /// The spec provided when creating this decoration. Can be useful
  /// if you've stored extra information in that object.
  get spec() { return this.type.spec }

  /// @internal
  get inline() { return this.type instanceof InlineType }

  /// @internal
  get widget() { return this.type instanceof WidgetType }
}

/// A set of attributes to add to a decorated node. Most properties
/// simply directly correspond to DOM attributes of the same name,
/// which will be set to the property's value. These are exceptions:
export type DecorationAttrs = {
  /// When non-null, the target node is wrapped in a DOM element of
  /// this type (and the other attributes are applied to this element).
  nodeName?: string

  /// A CSS class name or a space-separated set of class names to be
  /// _added_ to the classes that the node already had.
  class?: string

  /// A string of CSS to be _added_ to the node's existing `style` property.
  style?: string

  /// Any other properties are treated as regular DOM attributes.
  [attribute: string]: string | undefined
}

const none: readonly any[] = [], noSpec = {}

/// An object that can [provide](#view.EditorProps.decorations)
/// decorations. Implemented by [`DecorationSet`](#view.DecorationSet),
/// and passed to [node views](#view.EditorProps.nodeViews).
export interface DecorationSource {
  /// Map the set of decorations in response to a change in the
  /// document.
  map: (mapping: Mapping, node: Node) => DecorationSource
  /// @internal
  locals(node: Node): readonly Decoration[]
  /// Extract a DecorationSource containing decorations for the given child node at the given offset.
  forChild(offset: number, child: Node): DecorationSource
  /// @internal
  eq(other: DecorationSource): boolean
  /// Call the given function for each decoration set in the group.
  forEachSet(f: (set: DecorationSet) => void): void
}

/// A collection of [decorations](#view.Decoration), organized in such
/// a way that the drawing algorithm can efficiently use and compare
/// them. This is a persistent data structure—it is not modified,
/// updates create a new value.
export class DecorationSet implements DecorationSource {
  /// @internal
  local: readonly Decoration[]
  /// @internal
  children: readonly (number | DecorationSet)[]

  /// @internal
  constructor(local: readonly Decoration[], children: readonly (number | DecorationSet)[]) {
    this.local = local.length ? local : none
    this.children = children.length ? children : none
  }

  /// Create a set of decorations, using the structure of the given
  /// document. This will consume (modify) the `decorations` array, so
  /// you must make a copy if you want need to preserve that.
  static create(doc: Node, decorations: Decoration[]) {
    return decorations.length ? buildTree(decorations, doc, 0, noSpec) : empty
  }

  /// Find all decorations in this set which touch the given range
  /// (including decorations that start or end directly at the
  /// boundaries) and match the given predicate on their spec. When
  /// `start` and `end` are omitted, all decorations in the set are
  /// considered. When `predicate` isn't given, all decorations are
  /// assumed to match.
  find(start?: number, end?: number, predicate?: (spec: any) => boolean): Decoration[] {
    let result: Decoration[] = []
    this.findInner(start == null ? 0 : start, end == null ? 1e9 : end, result, 0, predicate)
    return result
  }

  private findInner(start: number, end: number, result: Decoration[], offset: number, predicate?: (spec: any) => boolean) {
    for (let i = 0; i < this.local.length; i++) {
      let span = this.local[i]
      if (span.from <= end && span.to >= start && (!predicate || predicate(span.spec)))
        result.push(span.copy(span.from + offset, span.to + offset))
    }
    for (let i = 0; i < this.children.length; i += 3) {
      if ((this.children[i] as number) < end && (this.children[i + 1] as number) > start) {
        let childOff = (this.children[i] as number) + 1
        ;(this.children[i + 2] as DecorationSet).findInner(start - childOff, end - childOff,
                                                           result, offset + childOff, predicate)
      }
    }
  }

  /// Map the set of decorations in response to a change in the
  /// document.
  map(mapping: Mapping, doc: Node, options?: {
    /// When given, this function will be called for each decoration
    /// that gets dropped as a result of the mapping, passing the
    /// spec of that decoration.
    onRemove?: (decorationSpec: any) => void
  }) {
    if (this == empty || mapping.maps.length == 0) return this
    return this.mapInner(mapping, doc, 0, 0, options || noSpec)
  }

  /// @internal
  mapInner(mapping: Mapping, node: Node, offset: number, oldOffset: number, options: {
    onRemove?: (decorationSpec: any) => void
  }) {
    let newLocal: Decoration[] | undefined
    for (let i = 0; i < this.local.length; i++) {
      let mapped = this.local[i].map(mapping, offset, oldOffset)
      if (mapped && mapped.type.valid(node, mapped)) (newLocal || (newLocal = [])).push(mapped)
      else if (options.onRemove) options.onRemove(this.local[i].spec)
    }

    if (this.children.length)
      return mapChildren(this.children, newLocal || [], mapping, node, offset, oldOffset, options)
    else
      return newLocal ? new DecorationSet(newLocal.sort(byPos), none) : empty
  }

  /// Add the given array of decorations to the ones in the set,
  /// producing a new set. Consumes the `decorations` array. Needs
  /// access to the current document to create the appropriate tree
  /// structure.
  add(doc: Node, decorations: Decoration[]) {
    if (!decorations.length) return this
    if (this == empty) return DecorationSet.create(doc, decorations)
    return this.addInner(doc, decorations, 0)
  }

  private addInner(doc: Node, decorations: Decoration[], offset: number) {
    let children: (number | DecorationSet)[] | undefined, childIndex = 0
    doc.forEach((childNode, childOffset) => {
      let baseOffset = childOffset + offset, found
      if (!(found = takeSpansForNode(decorations, childNode, baseOffset))) return

      if (!children) children = this.children.slice()
      while (childIndex < children.length && (children[childIndex] as number) < childOffset) childIndex += 3
      if (children[childIndex] == childOffset)
        children[childIndex + 2] = (children[childIndex + 2] as DecorationSet).addInner(childNode, found, baseOffset + 1)
      else
        children.splice(childIndex, 0, childOffset, childOffset + childNode.nodeSize, buildTree(found, childNode, baseOffset + 1, noSpec))
      childIndex += 3
    })

    let local = moveSpans(childIndex ? withoutNulls(decorations) : decorations, -offset)
    for (let i = 0; i < local.length; i++) if (!local[i].type.valid(doc, local[i])) local.splice(i--, 1)

    return new DecorationSet(local.length ? this.local.concat(local).sort(byPos) : this.local,
                             children || this.children)
  }

  /// Create a new set that contains the decorations in this set, minus
  /// the ones in the given array.
  remove(decorations: Decoration[]) {
    if (decorations.length == 0 || this == empty) return this
    return this.removeInner(decorations, 0)
  }

  private removeInner(decorations: (Decoration | null)[], offset: number) {
    let children = this.children as (number | DecorationSet)[], local = this.local as Decoration[]
    for (let i = 0; i < children.length; i += 3) {
      let found: Decoration[] | undefined
      let from = (children[i] as number) + offset, to = (children[i + 1] as number) + offset
      for (let j = 0, span; j < decorations.length; j++) if (span = decorations[j]) {
        if (span.from > from && span.to < to) {
          decorations[j] = null
          ;(found || (found = [])).push(span)
        }
      }
      if (!found) continue
      if (children == this.children) children = this.children.slice()
      let removed = (children[i + 2] as DecorationSet).removeInner(found, from + 1)
      if (removed != empty) {
        children[i + 2] = removed
      } else {
        children.splice(i, 3)
        i -= 3
      }
    }
    if (local.length) for (let i = 0, span; i < decorations.length; i++) if (span = decorations[i]) {
      for (let j = 0; j < local.length; j++) if (local[j].eq(span, offset)) {
        if (local == this.local) local = this.local.slice()
        local.splice(j--, 1)
      }
    }
    if (children == this.children && local == this.local) return this
    return local.length || children.length ? new DecorationSet(local, children) : empty
  }

  forChild(offset: number, node: Node): DecorationSet | DecorationGroup {
    if (this == empty) return this
    if (node.isLeaf) return DecorationSet.empty

    let child, local: Decoration[] | undefined
    for (let i = 0; i < this.children.length; i += 3) if ((this.children[i] as number) >= offset) {
      if (this.children[i] == offset) child = this.children[i + 2] as DecorationSet
      break
    }
    let start = offset + 1, end = start + node.content.size
    for (let i = 0; i < this.local.length; i++) {
      let dec = this.local[i]
      if (dec.from < end && dec.to > start && (dec.type instanceof InlineType)) {
        let from = Math.max(start, dec.from) - start, to = Math.min(end, dec.to) - start
        if (from < to) (local || (local = [])).push(dec.copy(from, to))
      }
    }
    if (local) {
      let localSet = new DecorationSet(local.sort(byPos), none)
      return child ? new DecorationGroup([localSet, child]) : localSet
    }
    return child || empty
  }

  /// @internal
  eq(other: DecorationSet) {
    if (this == other) return true
    if (!(other instanceof DecorationSet) ||
        this.local.length != other.local.length ||
        this.children.length != other.children.length) return false
    for (let i = 0; i < this.local.length; i++)
      if (!this.local[i].eq(other.local[i])) return false
    for (let i = 0; i < this.children.length; i += 3)
      if (this.children[i] != other.children[i] ||
          this.children[i + 1] != other.children[i + 1] ||
          !(this.children[i + 2] as DecorationSet).eq(other.children[i + 2] as DecorationSet))
        return false
    return true
  }

  /// @internal
  locals(node: Node) {
    return removeOverlap(this.localsInner(node))
  }

  /// @internal
  localsInner(node: Node): readonly Decoration[] {
    if (this == empty) return none
    if (node.inlineContent || !this.local.some(InlineType.is)) return this.local
    let result = []
    for (let i = 0; i < this.local.length; i++) {
      if (!(this.local[i].type instanceof InlineType))
        result.push(this.local[i])
    }
    return result
  }

  /// The empty set of decorations.
  static empty: DecorationSet = new DecorationSet([], [])

  /// @internal
  static removeOverlap = removeOverlap

  forEachSet(f: (set: DecorationSet) => void) { f(this) }
}

const empty = DecorationSet.empty

// An abstraction that allows the code dealing with decorations to
// treat multiple DecorationSet objects as if it were a single object
// with (a subset of) the same interface.
class DecorationGroup implements DecorationSource {
  constructor(readonly members: readonly DecorationSet[]) {}

  map(mapping: Mapping, doc: Node) {
    const mappedDecos = this.members.map(
      member => member.map(mapping, doc, noSpec)
    )
    return DecorationGroup.from(mappedDecos)
  }

  forChild(offset: number, child: Node) {
    if (child.isLeaf) return DecorationSet.empty
    let found: DecorationSet[] = []
    for (let i = 0; i < this.members.length; i++) {
      let result = this.members[i].forChild(offset, child)
      if (result == empty) continue
      if (result instanceof DecorationGroup) found = found.concat(result.members)
      else found.push(result)
    }
    return DecorationGroup.from(found)
  }

  eq(other: DecorationGroup) {
    if (!(other instanceof DecorationGroup) ||
        other.members.length != this.members.length) return false
    for (let i = 0; i < this.members.length; i++)
      if (!this.members[i].eq(other.members[i])) return false
    return true
  }

  locals(node: Node) {
    let result: Decoration[] | undefined, sorted = true
    for (let i = 0; i < this.members.length; i++) {
      let locals = this.members[i].localsInner(node)
      if (!locals.length) continue
      if (!result) {
        result = locals as Decoration[]
      } else {
        if (sorted) {
          result = result.slice()
          sorted = false
        }
        for (let j = 0; j < locals.length; j++) result.push(locals[j])
      }
    }
    return result ? removeOverlap(sorted ? result : result.sort(byPos)) : none
  }

  // Create a group for the given array of decoration sets, or return
  // a single set when possible.
  static from(members: readonly DecorationSource[]): DecorationSource {
    switch (members.length) {
      case 0: return empty
      case 1: return members[0]
      default: return new DecorationGroup(
        members.every(m => m instanceof DecorationSet) ? members as DecorationSet[] :
          members.reduce((r, m) => r.concat(m instanceof DecorationSet ? m : (m as DecorationGroup).members),
                         [] as DecorationSet[]))
    }
  }

  forEachSet(f: (set: DecorationSet) => void) {
    for (let i = 0; i < this.members.length; i++) this.members[i].forEachSet(f)
  }
}

function mapChildren(
  oldChildren: readonly (number | DecorationSet)[],
  newLocal: Decoration[],
  mapping: Mapping,
  node: Node,
  offset: number,
  oldOffset: number,
  options: {onRemove?: (decorationSpec: any) => void}
) {
  let children = oldChildren.slice() as (number | DecorationSet)[]

  // Mark the children that are directly touched by changes, and
  // move those that are after the changes.
  for (let i = 0, baseOffset = oldOffset; i < mapping.maps.length; i++) {
    let moved = 0
    mapping.maps[i].forEach((oldStart: number, oldEnd: number, newStart: number, newEnd: number) => {
      let dSize = (newEnd - newStart) - (oldEnd - oldStart)
      for (let i = 0; i < children.length; i += 3) {
        let end = children[i + 1] as number
        if (end < 0 || oldStart > end + baseOffset - moved) continue
        let start = (children[i] as number) + baseOffset - moved
        if (oldEnd >= start) {
          children[i + 1] = oldStart <= start ? -2 : -1
        } else if (oldStart >= baseOffset && dSize) {
          ;(children[i] as number) += dSize
          ;(children[i + 1] as number) += dSize
        }
      }
      moved += dSize
    })
    baseOffset = mapping.maps[i].map(baseOffset, -1)
  }

  // Find the child nodes that still correspond to a single node,
  // recursively call mapInner on them and update their positions.
  let mustRebuild = false
  for (let i = 0; i < children.length; i += 3) if ((children[i + 1] as number) < 0) { // Touched nodes
    if (children[i + 1] == -2) {
      mustRebuild = true
      children[i + 1] = -1
      continue
    }
    let from = mapping.map((oldChildren[i] as number) + oldOffset), fromLocal = from - offset
    if (fromLocal < 0 || fromLocal >= node.content.size) {
      mustRebuild = true
      continue
    }
    // Must read oldChildren because children was tagged with -1
    let to = mapping.map((oldChildren[i + 1] as number) + oldOffset, -1), toLocal = to - offset
    let {index, offset: childOffset} = node.content.findIndex(fromLocal)
    let childNode = node.maybeChild(index)
    if (childNode && childOffset == fromLocal && childOffset + childNode.nodeSize == toLocal) {
      let mapped = (children[i + 2] as DecorationSet)
                     .mapInner(mapping, childNode, from + 1, (oldChildren[i] as number) + oldOffset + 1, options)
      if (mapped != empty) {
        children[i] = fromLocal
        children[i + 1] = toLocal
        children[i + 2] = mapped
      } else {
        children[i + 1] = -2
        mustRebuild = true
      }
    } else {
      mustRebuild = true
    }
  }

  // Remaining children must be collected and rebuilt into the appropriate structure
  if (mustRebuild) {
    let decorations = mapAndGatherRemainingDecorations(children, oldChildren, newLocal, mapping,
                                                       offset, oldOffset, options)
    let built = buildTree(decorations, node, 0, options)
    newLocal = built.local as Decoration[]
    for (let i = 0; i < children.length; i += 3) if ((children[i + 1] as number) < 0) {
      children.splice(i, 3)
      i -= 3
    }
    for (let i = 0, j = 0; i < built.children.length; i += 3) {
      let from = built.children[i]
      while (j < children.length && children[j] < from) j += 3
      children.splice(j, 0, built.children[i], built.children[i + 1], built.children[i + 2])
    }
  }

  return new DecorationSet(newLocal.sort(byPos), children)
}

function moveSpans(spans: Decoration[], offset: number) {
  if (!offset || !spans.length) return spans
  let result = []
  for (let i = 0; i < spans.length; i++) {
    let span = spans[i]
    result.push(new Decoration(span.from + offset, span.to + offset, span.type))
  }
  return result
}

function mapAndGatherRemainingDecorations(
  children: (number | DecorationSet)[],
  oldChildren: readonly (number | DecorationSet)[],
  decorations: Decoration[],
  mapping: Mapping,
  offset: number,
  oldOffset: number,
  options: {onRemove?: (decorationSpec: any) => void}
) {
  // Gather all decorations from the remaining marked children
  function gather(set: DecorationSet, oldOffset: number) {
    for (let i = 0; i < set.local.length; i++) {
      let mapped = set.local[i].map(mapping, offset, oldOffset)
      if (mapped) decorations.push(mapped)
      else if (options.onRemove) options.onRemove(set.local[i].spec)
    }
    for (let i = 0; i < set.children.length; i += 3)
      gather(set.children[i + 2] as DecorationSet, set.children[i] as number + oldOffset + 1)
  }
  for (let i = 0; i < children.length; i += 3) if (children[i + 1] == -1)
    gather(children[i + 2] as DecorationSet, oldChildren[i] as number + oldOffset + 1)

  return decorations
}

function takeSpansForNode(spans: (Decoration | null)[], node: Node, offset: number): Decoration[] | null {
  if (node.isLeaf) return null
  let end = offset + node.nodeSize, found = null
  for (let i = 0, span; i < spans.length; i++) {
    if ((span = spans[i]) && span.from > offset && span.to < end) {
      ;(found || (found = [])).push(span)
      spans[i] = null
    }
  }
  return found
}

function withoutNulls<T>(array: readonly (T | null)[]): T[] {
  let result: T[] = []
  for (let i = 0; i < array.length; i++)
    if (array[i] != null) result.push(array[i]!)
  return result
}

// Build up a tree that corresponds to a set of decorations. `offset`
// is a base offset that should be subtracted from the `from` and `to`
// positions in the spans (so that we don't have to allocate new spans
// for recursive calls).
function buildTree(
  spans: Decoration[],
  node: Node,
  offset: number,
  options: {onRemove?: (decorationSpec: any) => void}
) {
  let children: (DecorationSet | number)[] = [], hasNulls = false
  node.forEach((childNode, localStart) => {
    let found = takeSpansForNode(spans, childNode, localStart + offset)
    if (found) {
      hasNulls = true
      let subtree = buildTree(found, childNode, offset + localStart + 1, options)
      if (subtree != empty)
        children.push(localStart, localStart + childNode.nodeSize, subtree)
    }
  })
  let locals = moveSpans(hasNulls ? withoutNulls(spans) : spans, -offset).sort(byPos)
  for (let i = 0; i < locals.length; i++) if (!locals[i].type.valid(node, locals[i])) {
    if (options.onRemove) options.onRemove(locals[i].spec)
    locals.splice(i--, 1)
  }
  return locals.length || children.length ? new DecorationSet(locals, children) : empty
}

// Used to sort decorations so that ones with a low start position
// come first, and within a set with the same start position, those
// with an smaller end position come first.
function byPos(a: Decoration, b: Decoration) {
  return a.from - b.from || a.to - b.to
}

// Scan a sorted array of decorations for partially overlapping spans,
// and split those so that only fully overlapping spans are left (to
// make subsequent rendering easier). Will return the input array if
// no partially overlapping spans are found (the common case).
function removeOverlap(spans: readonly Decoration[]): Decoration[] {
  let working: Decoration[] = spans as Decoration[]
  for (let i = 0; i < working.length - 1; i++) {
    let span = working[i]
    if (span.from != span.to) for (let j = i + 1; j < working.length; j++) {
      let next = working[j]
      if (next.from == span.from) {
        if (next.to != span.to) {
          if (working == spans) working = spans.slice()
          // Followed by a partially overlapping larger span. Split that
          // span.
          working[j] = next.copy(next.from, span.to)
          insertAhead(working, j + 1, next.copy(span.to, next.to))
        }
        continue
      } else {
        if (next.from < span.to) {
          if (working == spans) working = spans.slice()
          // The end of this one overlaps with a subsequent span. Split
          // this one.
          working[i] = span.copy(span.from, next.from)
          insertAhead(working, j, span.copy(next.from, span.to))
        }
        break
      }
    }
  }
  return working
}

function insertAhead(array: Decoration[], i: number, deco: Decoration) {
  while (i < array.length && byPos(deco, array[i]) > 0) i++
  array.splice(i, 0, deco)
}

// Get the decorations associated with the current props of a view.
export function viewDecorations(view: EditorView): DecorationSource {
  let found: DecorationSource[] = []
  view.someProp("decorations", f => {
    let result = f(view.state)
    if (result && result != empty) found.push(result)
  })
  if (view.cursorWrapper)
    found.push(DecorationSet.create(view.state.doc, [view.cursorWrapper.deco]))
  return DecorationGroup.from(found)
}
