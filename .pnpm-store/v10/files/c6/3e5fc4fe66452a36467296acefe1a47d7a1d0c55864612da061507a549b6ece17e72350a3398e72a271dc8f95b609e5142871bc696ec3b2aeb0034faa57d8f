import {Fragment} from "./fragment"
import {Mark} from "./mark"
import {Schema, NodeType, Attrs, MarkType} from "./schema"
import {Slice, replace} from "./replace"
import {ResolvedPos} from "./resolvedpos"
import {compareDeep} from "./comparedeep"

const emptyAttrs: Attrs = Object.create(null)

/// This class represents a node in the tree that makes up a
/// ProseMirror document. So a document is an instance of `Node`, with
/// children that are also instances of `Node`.
///
/// Nodes are persistent data structures. Instead of changing them, you
/// create new ones with the content you want. Old ones keep pointing
/// at the old document shape. This is made cheaper by sharing
/// structure between the old and new data as much as possible, which a
/// tree shape like this (without back pointers) makes easy.
///
/// **Do not** directly mutate the properties of a `Node` object. See
/// [the guide](/docs/guide/#doc) for more information.
export class Node {
  /// @internal
  constructor(
    /// The type of node that this is.
    readonly type: NodeType,
    /// An object mapping attribute names to values. The kind of
    /// attributes allowed and required are
    /// [determined](#model.NodeSpec.attrs) by the node type.
    readonly attrs: Attrs,
    // A fragment holding the node's children.
    content?: Fragment | null,
    /// The marks (things like whether it is emphasized or part of a
    /// link) applied to this node.
    readonly marks = Mark.none
  ) {
    this.content = content || Fragment.empty
  }

  /// A container holding the node's children.
  readonly content: Fragment

  /// For text nodes, this contains the node's text content.
  readonly text: string | undefined

  /// The size of this node, as defined by the integer-based [indexing
  /// scheme](/docs/guide/#doc.indexing). For text nodes, this is the
  /// amount of characters. For other leaf nodes, it is one. For
  /// non-leaf nodes, it is the size of the content plus two (the
  /// start and end token).
  get nodeSize(): number { return this.isLeaf ? 1 : 2 + this.content.size }

  /// The number of children that the node has.
  get childCount() { return this.content.childCount }

  /// Get the child node at the given index. Raises an error when the
  /// index is out of range.
  child(index: number) { return this.content.child(index) }

  /// Get the child node at the given index, if it exists.
  maybeChild(index: number) { return this.content.maybeChild(index) }

  /// Call `f` for every child node, passing the node, its offset
  /// into this parent node, and its index.
  forEach(f: (node: Node, offset: number, index: number) => void) { this.content.forEach(f) }

  /// Invoke a callback for all descendant nodes recursively between
  /// the given two positions that are relative to start of this
  /// node's content. The callback is invoked with the node, its
  /// position relative to the original node (method receiver), 
  /// its parent node, and its child index. When the callback returns
  /// false for a given node, that node's children will not be
  /// recursed over. The last parameter can be used to specify a 
  /// starting position to count from.
  nodesBetween(from: number, to: number,
               f: (node: Node, pos: number, parent: Node | null, index: number) => void | boolean,
               startPos = 0) {
    this.content.nodesBetween(from, to, f, startPos, this)
  }

  /// Call the given callback for every descendant node. Doesn't
  /// descend into a node when the callback returns `false`.
  descendants(f: (node: Node, pos: number, parent: Node | null, index: number) => void | boolean) {
    this.nodesBetween(0, this.content.size, f)
  }

  /// Concatenates all the text nodes found in this fragment and its
  /// children.
  get textContent() {
    return (this.isLeaf && this.type.spec.leafText)
      ? this.type.spec.leafText(this)
      : this.textBetween(0, this.content.size, "")
  }

  /// Get all text between positions `from` and `to`. When
  /// `blockSeparator` is given, it will be inserted to separate text
  /// from different block nodes. If `leafText` is given, it'll be
  /// inserted for every non-text leaf node encountered, otherwise
  /// [`leafText`](#model.NodeSpec^leafText) will be used.
  textBetween(from: number, to: number, blockSeparator?: string | null,
              leafText?: null | string | ((leafNode: Node) => string)) {
    return this.content.textBetween(from, to, blockSeparator, leafText)
  }

  /// Returns this node's first child, or `null` if there are no
  /// children.
  get firstChild(): Node | null { return this.content.firstChild }

  /// Returns this node's last child, or `null` if there are no
  /// children.
  get lastChild(): Node | null { return this.content.lastChild }

  /// Test whether two nodes represent the same piece of document.
  eq(other: Node) {
    return this == other || (this.sameMarkup(other) && this.content.eq(other.content))
  }

  /// Compare the markup (type, attributes, and marks) of this node to
  /// those of another. Returns `true` if both have the same markup.
  sameMarkup(other: Node) {
    return this.hasMarkup(other.type, other.attrs, other.marks)
  }

  /// Check whether this node's markup correspond to the given type,
  /// attributes, and marks.
  hasMarkup(type: NodeType, attrs?: Attrs | null, marks?: readonly Mark[]): boolean {
    return this.type == type &&
      compareDeep(this.attrs, attrs || type.defaultAttrs || emptyAttrs) &&
      Mark.sameSet(this.marks, marks || Mark.none)
  }

  /// Create a new node with the same markup as this node, containing
  /// the given content (or empty, if no content is given).
  copy(content: Fragment | null = null): Node {
    if (content == this.content) return this
    return new Node(this.type, this.attrs, content, this.marks)
  }

  /// Create a copy of this node, with the given set of marks instead
  /// of the node's own marks.
  mark(marks: readonly Mark[]): Node {
    return marks == this.marks ? this : new Node(this.type, this.attrs, this.content, marks)
  }

  /// Create a copy of this node with only the content between the
  /// given positions. If `to` is not given, it defaults to the end of
  /// the node.
  cut(from: number, to: number = this.content.size): Node {
    if (from == 0 && to == this.content.size) return this
    return this.copy(this.content.cut(from, to))
  }

  /// Cut out the part of the document between the given positions, and
  /// return it as a `Slice` object.
  slice(from: number, to: number = this.content.size, includeParents = false) {
    if (from == to) return Slice.empty

    let $from = this.resolve(from), $to = this.resolve(to)
    let depth = includeParents ? 0 : $from.sharedDepth(to)
    let start = $from.start(depth), node = $from.node(depth)
    let content = node.content.cut($from.pos - start, $to.pos - start)
    return new Slice(content, $from.depth - depth, $to.depth - depth)
  }

  /// Replace the part of the document between the given positions with
  /// the given slice. The slice must 'fit', meaning its open sides
  /// must be able to connect to the surrounding content, and its
  /// content nodes must be valid children for the node they are placed
  /// into. If any of this is violated, an error of type
  /// [`ReplaceError`](#model.ReplaceError) is thrown.
  replace(from: number, to: number, slice: Slice) {
    return replace(this.resolve(from), this.resolve(to), slice)
  }

  /// Find the node directly after the given position.
  nodeAt(pos: number): Node | null {
    for (let node: Node | null = this;;) {
      let {index, offset} = node.content.findIndex(pos)
      node = node.maybeChild(index)
      if (!node) return null
      if (offset == pos || node.isText) return node
      pos -= offset + 1
    }
  }

  /// Find the (direct) child node after the given offset, if any,
  /// and return it along with its index and offset relative to this
  /// node.
  childAfter(pos: number): {node: Node | null, index: number, offset: number} {
    let {index, offset} = this.content.findIndex(pos)
    return {node: this.content.maybeChild(index), index, offset}
  }

  /// Find the (direct) child node before the given offset, if any,
  /// and return it along with its index and offset relative to this
  /// node.
  childBefore(pos: number): {node: Node | null, index: number, offset: number} {
    if (pos == 0) return {node: null, index: 0, offset: 0}
    let {index, offset} = this.content.findIndex(pos)
    if (offset < pos) return {node: this.content.child(index), index, offset}
    let node = this.content.child(index - 1)
    return {node, index: index - 1, offset: offset - node.nodeSize}
  }

  /// Resolve the given position in the document, returning an
  /// [object](#model.ResolvedPos) with information about its context.
  resolve(pos: number) { return ResolvedPos.resolveCached(this, pos) }

  /// @internal
  resolveNoCache(pos: number) { return ResolvedPos.resolve(this, pos) }

  /// Test whether a given mark or mark type occurs in this document
  /// between the two given positions.
  rangeHasMark(from: number, to: number, type: Mark | MarkType): boolean {
    let found = false
    if (to > from) this.nodesBetween(from, to, node => {
      if (type.isInSet(node.marks)) found = true
      return !found
    })
    return found
  }

  /// True when this is a block (non-inline node)
  get isBlock() { return this.type.isBlock }

  /// True when this is a textblock node, a block node with inline
  /// content.
  get isTextblock() { return this.type.isTextblock }

  /// True when this node allows inline content.
  get inlineContent() { return this.type.inlineContent }

  /// True when this is an inline node (a text node or a node that can
  /// appear among text).
  get isInline() { return this.type.isInline }

  /// True when this is a text node.
  get isText() { return this.type.isText }

  /// True when this is a leaf node.
  get isLeaf() { return this.type.isLeaf }

  /// True when this is an atom, i.e. when it does not have directly
  /// editable content. This is usually the same as `isLeaf`, but can
  /// be configured with the [`atom` property](#model.NodeSpec.atom)
  /// on a node's spec (typically used when the node is displayed as
  /// an uneditable [node view](#view.NodeView)).
  get isAtom() { return this.type.isAtom }

  /// Return a string representation of this node for debugging
  /// purposes.
  toString(): string {
    if (this.type.spec.toDebugString) return this.type.spec.toDebugString(this)
    let name = this.type.name
    if (this.content.size)
      name += "(" + this.content.toStringInner() + ")"
    return wrapMarks(this.marks, name)
  }

  /// Get the content match in this node at the given index.
  contentMatchAt(index: number) {
    let match = this.type.contentMatch.matchFragment(this.content, 0, index)
    if (!match) throw new Error("Called contentMatchAt on a node with invalid content")
    return match
  }

  /// Test whether replacing the range between `from` and `to` (by
  /// child index) with the given replacement fragment (which defaults
  /// to the empty fragment) would leave the node's content valid. You
  /// can optionally pass `start` and `end` indices into the
  /// replacement fragment.
  canReplace(from: number, to: number, replacement = Fragment.empty, start = 0, end = replacement.childCount) {
    let one = this.contentMatchAt(from).matchFragment(replacement, start, end)
    let two = one && one.matchFragment(this.content, to)
    if (!two || !two.validEnd) return false
    for (let i = start; i < end; i++) if (!this.type.allowsMarks(replacement.child(i).marks)) return false
    return true
  }

  /// Test whether replacing the range `from` to `to` (by index) with
  /// a node of the given type would leave the node's content valid.
  canReplaceWith(from: number, to: number, type: NodeType, marks?: readonly Mark[]) {
    if (marks && !this.type.allowsMarks(marks)) return false
    let start = this.contentMatchAt(from).matchType(type)
    let end = start && start.matchFragment(this.content, to)
    return end ? end.validEnd : false
  }

  /// Test whether the given node's content could be appended to this
  /// node. If that node is empty, this will only return true if there
  /// is at least one node type that can appear in both nodes (to avoid
  /// merging completely incompatible nodes).
  canAppend(other: Node) {
    if (other.content.size) return this.canReplace(this.childCount, this.childCount, other.content)
    else return this.type.compatibleContent(other.type)
  }

  /// Check whether this node and its descendants conform to the
  /// schema, and raise an exception when they do not.
  check() {
    this.type.checkContent(this.content)
    this.type.checkAttrs(this.attrs)
    let copy = Mark.none
    for (let i = 0; i < this.marks.length; i++) {
      let mark = this.marks[i]
      mark.type.checkAttrs(mark.attrs)
      copy = mark.addToSet(copy)
    }
    if (!Mark.sameSet(copy, this.marks))
      throw new RangeError(`Invalid collection of marks for node ${this.type.name}: ${this.marks.map(m => m.type.name)}`)
    this.content.forEach(node => node.check())
  }

  /// Return a JSON-serializeable representation of this node.
  toJSON(): any {
    let obj: any = {type: this.type.name}
    for (let _ in this.attrs) {
      obj.attrs = this.attrs
      break
    }
    if (this.content.size)
      obj.content = this.content.toJSON()
    if (this.marks.length)
      obj.marks = this.marks.map(n => n.toJSON())
    return obj
  }

  /// Deserialize a node from its JSON representation.
  static fromJSON(schema: Schema, json: any): Node {
    if (!json) throw new RangeError("Invalid input for Node.fromJSON")
    let marks: Mark[] | undefined = undefined
    if (json.marks) {
      if (!Array.isArray(json.marks)) throw new RangeError("Invalid mark data for Node.fromJSON")
      marks = json.marks.map(schema.markFromJSON)
    }
    if (json.type == "text") {
      if (typeof json.text != "string") throw new RangeError("Invalid text node in JSON")
      return schema.text(json.text, marks)
    }
    let content = Fragment.fromJSON(schema, json.content)
    let node = schema.nodeType(json.type).create(json.attrs, content, marks)
    node.type.checkAttrs(node.attrs)
    return node
  }
}

;(Node.prototype as any).text = undefined

export class TextNode extends Node {
  readonly text: string

  /// @internal
  constructor(type: NodeType, attrs: Attrs, content: string, marks?: readonly Mark[]) {
    super(type, attrs, null, marks)
    if (!content) throw new RangeError("Empty text nodes are not allowed")
    this.text = content
  }

  toString() {
    if (this.type.spec.toDebugString) return this.type.spec.toDebugString(this)
    return wrapMarks(this.marks, JSON.stringify(this.text))
  }

  get textContent() { return this.text }

  textBetween(from: number, to: number) { return this.text.slice(from, to) }

  get nodeSize() { return this.text.length }

  mark(marks: readonly Mark[]) {
    return marks == this.marks ? this : new TextNode(this.type, this.attrs, this.text, marks)
  }

  withText(text: string) {
    if (text == this.text) return this
    return new TextNode(this.type, this.attrs, text, this.marks)
  }

  cut(from = 0, to = this.text.length) {
    if (from == 0 && to == this.text.length) return this
    return this.withText(this.text.slice(from, to))
  }

  eq(other: Node) {
    return this.sameMarkup(other) && this.text == other.text
  }

  toJSON() {
    let base = super.toJSON()
    base.text = this.text
    return base
  }
}

function wrapMarks(marks: readonly Mark[], str: string) {
  for (let i = marks.length - 1; i >= 0; i--)
    str = marks[i].type.name + "(" + str + ")"
  return str
}
