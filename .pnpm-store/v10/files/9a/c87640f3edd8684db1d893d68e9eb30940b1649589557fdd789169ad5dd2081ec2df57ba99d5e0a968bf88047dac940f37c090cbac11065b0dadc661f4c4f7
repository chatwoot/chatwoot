import {Node, NodeType, Mark, MarkType, ContentMatch, Slice, Fragment, NodeRange, Attrs} from "prosemirror-model"

import {Mapping} from "./map"
import {Step} from "./step"
import {addMark, removeMark, clearIncompatible} from "./mark"
import {replaceStep, replaceRange, replaceRangeWith, deleteRange} from "./replace"
import {lift, wrap, setBlockType, setNodeMarkup, split, join} from "./structure"
import {AttrStep, DocAttrStep} from "./attr_step"
import {AddNodeMarkStep, RemoveNodeMarkStep} from "./mark_step"

/// @internal
export let TransformError = class extends Error {}

TransformError = function TransformError(this: any, message: string) {
  let err = Error.call(this, message)
  ;(err as any).__proto__ = TransformError.prototype
  return err
} as any

TransformError.prototype = Object.create(Error.prototype)
TransformError.prototype.constructor = TransformError
TransformError.prototype.name = "TransformError"

/// Abstraction to build up and track an array of
/// [steps](#transform.Step) representing a document transformation.
///
/// Most transforming methods return the `Transform` object itself, so
/// that they can be chained.
export class Transform {
  /// The steps in this transform.
  readonly steps: Step[] = []
  /// The documents before each of the steps.
  readonly docs: Node[] = []
  /// A mapping with the maps for each of the steps in this transform.
  readonly mapping: Mapping = new Mapping

  /// Create a transform that starts with the given document.
  constructor(
    /// The current document (the result of applying the steps in the
    /// transform).
    public doc: Node
  ) {}

  /// The starting document.
  get before() { return this.docs.length ? this.docs[0] : this.doc }

  /// Apply a new step in this transform, saving the result. Throws an
  /// error when the step fails.
  step(step: Step) {
    let result = this.maybeStep(step)
    if (result.failed) throw new TransformError(result.failed)
    return this
  }

  /// Try to apply a step in this transformation, ignoring it if it
  /// fails. Returns the step result.
  maybeStep(step: Step) {
    let result = step.apply(this.doc)
    if (!result.failed) this.addStep(step, result.doc!)
    return result
  }

  /// True when the document has been changed (when there are any
  /// steps).
  get docChanged() {
    return this.steps.length > 0
  }

  /// @internal
  addStep(step: Step, doc: Node) {
    this.docs.push(this.doc)
    this.steps.push(step)
    this.mapping.appendMap(step.getMap())
    this.doc = doc
  }

  /// Replace the part of the document between `from` and `to` with the
  /// given `slice`.
  replace(from: number, to = from, slice = Slice.empty): this {
    let step = replaceStep(this.doc, from, to, slice)
    if (step) this.step(step)
    return this
  }

  /// Replace the given range with the given content, which may be a
  /// fragment, node, or array of nodes.
  replaceWith(from: number, to: number, content: Fragment | Node | readonly Node[]): this {
    return this.replace(from, to, new Slice(Fragment.from(content), 0, 0))
  }

  /// Delete the content between the given positions.
  delete(from: number, to: number): this {
    return this.replace(from, to, Slice.empty)
  }

  /// Insert the given content at the given position.
  insert(pos: number, content: Fragment | Node | readonly Node[]): this {
    return this.replaceWith(pos, pos, content)
  }

  /// Replace a range of the document with a given slice, using
  /// `from`, `to`, and the slice's
  /// [`openStart`](#model.Slice.openStart) property as hints, rather
  /// than fixed start and end points. This method may grow the
  /// replaced area or close open nodes in the slice in order to get a
  /// fit that is more in line with WYSIWYG expectations, by dropping
  /// fully covered parent nodes of the replaced region when they are
  /// marked [non-defining as
  /// context](#model.NodeSpec.definingAsContext), or including an
  /// open parent node from the slice that _is_ marked as [defining
  /// its content](#model.NodeSpec.definingForContent).
  ///
  /// This is the method, for example, to handle paste. The similar
  /// [`replace`](#transform.Transform.replace) method is a more
  /// primitive tool which will _not_ move the start and end of its given
  /// range, and is useful in situations where you need more precise
  /// control over what happens.
  replaceRange(from: number, to: number, slice: Slice): this {
    replaceRange(this, from, to, slice)
    return this
  }

  /// Replace the given range with a node, but use `from` and `to` as
  /// hints, rather than precise positions. When from and to are the same
  /// and are at the start or end of a parent node in which the given
  /// node doesn't fit, this method may _move_ them out towards a parent
  /// that does allow the given node to be placed. When the given range
  /// completely covers a parent node, this method may completely replace
  /// that parent node.
  replaceRangeWith(from: number, to: number, node: Node): this {
    replaceRangeWith(this, from, to, node)
    return this
  }

  /// Delete the given range, expanding it to cover fully covered
  /// parent nodes until a valid replace is found.
  deleteRange(from: number, to: number): this {
    deleteRange(this, from, to)
    return this
  }

  /// Split the content in the given range off from its parent, if there
  /// is sibling content before or after it, and move it up the tree to
  /// the depth specified by `target`. You'll probably want to use
  /// [`liftTarget`](#transform.liftTarget) to compute `target`, to make
  /// sure the lift is valid.
  lift(range: NodeRange, target: number): this {
    lift(this, range, target)
    return this
  }

  /// Join the blocks around the given position. If depth is 2, their
  /// last and first siblings are also joined, and so on.
  join(pos: number, depth: number = 1): this {
    join(this, pos, depth)
    return this
  }

  /// Wrap the given [range](#model.NodeRange) in the given set of wrappers.
  /// The wrappers are assumed to be valid in this position, and should
  /// probably be computed with [`findWrapping`](#transform.findWrapping).
  wrap(range: NodeRange, wrappers: readonly {type: NodeType, attrs?: Attrs | null}[]): this {
    wrap(this, range, wrappers)
    return this
  }

  /// Set the type of all textblocks (partly) between `from` and `to` to
  /// the given node type with the given attributes.
  setBlockType(from: number, to = from, type: NodeType, attrs: Attrs | null | ((oldNode: Node) => Attrs) = null): this {
    setBlockType(this, from, to, type, attrs)
    return this
  }

  /// Change the type, attributes, and/or marks of the node at `pos`.
  /// When `type` isn't given, the existing node type is preserved,
  setNodeMarkup(pos: number, type?: NodeType | null, attrs: Attrs | null = null, marks?: readonly Mark[]): this {
    setNodeMarkup(this, pos, type, attrs, marks)
    return this
  }

  /// Set a single attribute on a given node to a new value.
  /// The `pos` addresses the document content. Use `setDocAttribute`
  /// to set attributes on the document itself.
  setNodeAttribute(pos: number, attr: string, value: any): this {
    this.step(new AttrStep(pos, attr, value))
    return this
  }

  /// Set a single attribute on the document to a new value.
  setDocAttribute(attr: string, value: any): this {
    this.step(new DocAttrStep(attr, value))
    return this
  }

  /// Add a mark to the node at position `pos`.
  addNodeMark(pos: number, mark: Mark): this {
    this.step(new AddNodeMarkStep(pos, mark))
    return this
  }

  /// Remove a mark (or a mark of the given type) from the node at
  /// position `pos`.
  removeNodeMark(pos: number, mark: Mark | MarkType): this {
    if (!(mark instanceof Mark)) {
      let node = this.doc.nodeAt(pos)
      if (!node) throw new RangeError("No node at position " + pos)
      mark = mark.isInSet(node.marks)!
      if (!mark) return this
    }
    this.step(new RemoveNodeMarkStep(pos, mark))
    return this
  }

  /// Split the node at the given position, and optionally, if `depth` is
  /// greater than one, any number of nodes above that. By default, the
  /// parts split off will inherit the node type of the original node.
  /// This can be changed by passing an array of types and attributes to
  /// use after the split.
  split(pos: number, depth = 1, typesAfter?: (null | {type: NodeType, attrs?: Attrs | null})[]) {
    split(this, pos, depth, typesAfter)
    return this
  }

  /// Add the given mark to the inline content between `from` and `to`.
  addMark(from: number, to: number, mark: Mark): this {
    addMark(this, from, to, mark)
    return this
  }

  /// Remove marks from inline nodes between `from` and `to`. When
  /// `mark` is a single mark, remove precisely that mark. When it is
  /// a mark type, remove all marks of that type. When it is null,
  /// remove all marks of any type.
  removeMark(from: number, to: number, mark?: Mark | MarkType | null) {
    removeMark(this, from, to, mark)
    return this
  }

  /// Removes all marks and nodes from the content of the node at
  /// `pos` that don't match the given new parent node type. Accepts
  /// an optional starting [content match](#model.ContentMatch) as
  /// third argument.
  clearIncompatible(pos: number, parentType: NodeType, match?: ContentMatch) {
    clearIncompatible(this, pos, parentType, match)
    return this
  }
}
