import OrderedMap from "orderedmap"

import {Node, TextNode} from "./node"
import {Fragment} from "./fragment"
import {Mark} from "./mark"
import {ContentMatch} from "./content"
import {DOMOutputSpec} from "./to_dom"
import {ParseRule, TagParseRule} from "./from_dom"

/// An object holding the attributes of a node.
export type Attrs = {readonly [attr: string]: any}

// For node types where all attrs have a default value (or which don't
// have any attributes), build up a single reusable default attribute
// object, and use it for all nodes that don't specify specific
// attributes.
function defaultAttrs(attrs: {[name: string]: Attribute}) {
  let defaults = Object.create(null)
  for (let attrName in attrs) {
    let attr = attrs[attrName]
    if (!attr.hasDefault) return null
    defaults[attrName] = attr.default
  }
  return defaults
}

function computeAttrs(attrs: {[name: string]: Attribute}, value: Attrs | null) {
  let built = Object.create(null)
  for (let name in attrs) {
    let given = value && value[name]
    if (given === undefined) {
      let attr = attrs[name]
      if (attr.hasDefault) given = attr.default
      else throw new RangeError("No value supplied for attribute " + name)
    }
    built[name] = given
  }
  return built
}

export function checkAttrs(attrs: {[name: string]: Attribute}, values: Attrs, type: string, name: string) {
  for (let name in values)
    if (!(name in attrs)) throw new RangeError(`Unsupported attribute ${name} for ${type} of type ${name}`)
  for (let name in attrs) {
    let attr = attrs[name]
    if (attr.validate) attr.validate(values[name])
  }
}

function initAttrs(typeName: string, attrs?: {[name: string]: AttributeSpec}) {
  let result: {[name: string]: Attribute} = Object.create(null)
  if (attrs) for (let name in attrs) result[name] = new Attribute(typeName, name, attrs[name])
  return result
}

/// Node types are objects allocated once per `Schema` and used to
/// [tag](#model.Node.type) `Node` instances. They contain information
/// about the node type, such as its name and what kind of node it
/// represents.
export class NodeType {
  /// @internal
  groups: readonly string[]
  /// @internal
  attrs: {[name: string]: Attribute}
  /// @internal
  defaultAttrs: Attrs

  /// @internal
  constructor(
    /// The name the node type has in this schema.
    readonly name: string,
    /// A link back to the `Schema` the node type belongs to.
    readonly schema: Schema,
    /// The spec that this type is based on
    readonly spec: NodeSpec
  ) {
    this.groups = spec.group ? spec.group.split(" ") : []
    this.attrs = initAttrs(name, spec.attrs)
    this.defaultAttrs = defaultAttrs(this.attrs)

    // Filled in later
    ;(this as any).contentMatch = null
    ;(this as any).inlineContent = null

    this.isBlock = !(spec.inline || name == "text")
    this.isText = name == "text"
  }

  /// True if this node type has inline content.
  inlineContent!: boolean
  /// True if this is a block type
  isBlock: boolean
  /// True if this is the text node type.
  isText: boolean

  /// True if this is an inline type.
  get isInline() { return !this.isBlock }

  /// True if this is a textblock type, a block that contains inline
  /// content.
  get isTextblock() { return this.isBlock && this.inlineContent }

  /// True for node types that allow no content.
  get isLeaf() { return this.contentMatch == ContentMatch.empty }

  /// True when this node is an atom, i.e. when it does not have
  /// directly editable content.
  get isAtom() { return this.isLeaf || !!this.spec.atom }

  /// The starting match of the node type's content expression.
  contentMatch!: ContentMatch

  /// The set of marks allowed in this node. `null` means all marks
  /// are allowed.
  markSet: readonly MarkType[] | null = null

  /// The node type's [whitespace](#model.NodeSpec.whitespace) option.
  get whitespace(): "pre" | "normal" {
    return this.spec.whitespace || (this.spec.code ? "pre" : "normal")
  }

  /// Tells you whether this node type has any required attributes.
  hasRequiredAttrs() {
    for (let n in this.attrs) if (this.attrs[n].isRequired) return true
    return false
  }

  /// Indicates whether this node allows some of the same content as
  /// the given node type.
  compatibleContent(other: NodeType) {
    return this == other || this.contentMatch.compatible(other.contentMatch)
  }

  /// @internal
  computeAttrs(attrs: Attrs | null): Attrs {
    if (!attrs && this.defaultAttrs) return this.defaultAttrs
    else return computeAttrs(this.attrs, attrs)
  }

  /// Create a `Node` of this type. The given attributes are
  /// checked and defaulted (you can pass `null` to use the type's
  /// defaults entirely, if no required attributes exist). `content`
  /// may be a `Fragment`, a node, an array of nodes, or
  /// `null`. Similarly `marks` may be `null` to default to the empty
  /// set of marks.
  create(attrs: Attrs | null = null, content?: Fragment | Node | readonly Node[] | null, marks?: readonly Mark[]) {
    if (this.isText) throw new Error("NodeType.create can't construct text nodes")
    return new Node(this, this.computeAttrs(attrs), Fragment.from(content), Mark.setFrom(marks))
  }

  /// Like [`create`](#model.NodeType.create), but check the given content
  /// against the node type's content restrictions, and throw an error
  /// if it doesn't match.
  createChecked(attrs: Attrs | null = null, content?: Fragment | Node | readonly Node[] | null, marks?: readonly Mark[]) {
    content = Fragment.from(content)
    this.checkContent(content)
    return new Node(this, this.computeAttrs(attrs), content, Mark.setFrom(marks))
  }

  /// Like [`create`](#model.NodeType.create), but see if it is
  /// necessary to add nodes to the start or end of the given fragment
  /// to make it fit the node. If no fitting wrapping can be found,
  /// return null. Note that, due to the fact that required nodes can
  /// always be created, this will always succeed if you pass null or
  /// `Fragment.empty` as content.
  createAndFill(attrs: Attrs | null = null, content?: Fragment | Node | readonly Node[] | null, marks?: readonly Mark[]) {
    attrs = this.computeAttrs(attrs)
    content = Fragment.from(content)
    if (content.size) {
      let before = this.contentMatch.fillBefore(content)
      if (!before) return null
      content = before.append(content)
    }
    let matched = this.contentMatch.matchFragment(content)
    let after = matched && matched.fillBefore(Fragment.empty, true)
    if (!after) return null
    return new Node(this, attrs, (content as Fragment).append(after), Mark.setFrom(marks))
  }

  /// Returns true if the given fragment is valid content for this node
  /// type.
  validContent(content: Fragment) {
    let result = this.contentMatch.matchFragment(content)
    if (!result || !result.validEnd) return false
    for (let i = 0; i < content.childCount; i++)
      if (!this.allowsMarks(content.child(i).marks)) return false
    return true
  }

  /// Throws a RangeError if the given fragment is not valid content for this
  /// node type.
  /// @internal
  checkContent(content: Fragment) {
    if (!this.validContent(content))
      throw new RangeError(`Invalid content for node ${this.name}: ${content.toString().slice(0, 50)}`)
  }

  /// @internal
  checkAttrs(attrs: Attrs) {
    checkAttrs(this.attrs, attrs, "node", this.name)
  }

  /// Check whether the given mark type is allowed in this node.
  allowsMarkType(markType: MarkType) {
    return this.markSet == null || this.markSet.indexOf(markType) > -1
  }

  /// Test whether the given set of marks are allowed in this node.
  allowsMarks(marks: readonly Mark[]) {
    if (this.markSet == null) return true
    for (let i = 0; i < marks.length; i++) if (!this.allowsMarkType(marks[i].type)) return false
    return true
  }

  /// Removes the marks that are not allowed in this node from the given set.
  allowedMarks(marks: readonly Mark[]): readonly Mark[] {
    if (this.markSet == null) return marks
    let copy
    for (let i = 0; i < marks.length; i++) {
      if (!this.allowsMarkType(marks[i].type)) {
        if (!copy) copy = marks.slice(0, i)
      } else if (copy) {
        copy.push(marks[i])
      }
    }
    return !copy ? marks : copy.length ? copy : Mark.none
  }

  /// @internal
  static compile<Nodes extends string>(nodes: OrderedMap<NodeSpec>, schema: Schema<Nodes>): {readonly [name in Nodes]: NodeType} {
    let result = Object.create(null)
    nodes.forEach((name, spec) => result[name] = new NodeType(name, schema, spec))

    let topType = schema.spec.topNode || "doc"
    if (!result[topType]) throw new RangeError("Schema is missing its top node type ('" + topType + "')")
    if (!result.text) throw new RangeError("Every schema needs a 'text' type")
    for (let _ in result.text.attrs) throw new RangeError("The text node type should not have attributes")

    return result
  }
}

function validateType(typeName: string, attrName: string, type: string) {
  let types = type.split("|")
  return (value: any) => {
    let name = value === null ? "null" : typeof value
    if (types.indexOf(name) < 0) throw new RangeError(`Expected value of type ${types} for attribute ${attrName} on type ${typeName}, got ${name}`)
  }
}

// Attribute descriptors

class Attribute {
  hasDefault: boolean
  default: any
  validate: undefined | ((value: any) => void)

  constructor(typeName: string, attrName: string, options: AttributeSpec) {
    this.hasDefault = Object.prototype.hasOwnProperty.call(options, "default")
    this.default = options.default
    this.validate = typeof options.validate == "string" ? validateType(typeName, attrName, options.validate) : options.validate
  }

  get isRequired() {
    return !this.hasDefault
  }
}

// Marks

/// Like nodes, marks (which are associated with nodes to signify
/// things like emphasis or being part of a link) are
/// [tagged](#model.Mark.type) with type objects, which are
/// instantiated once per `Schema`.
export class MarkType {
  /// @internal
  attrs: {[name: string]: Attribute}
  /// @internal
  excluded!: readonly MarkType[]
  /// @internal
  instance: Mark | null

  /// @internal
  constructor(
    /// The name of the mark type.
    readonly name: string,
    /// @internal
    readonly rank: number,
    /// The schema that this mark type instance is part of.
    readonly schema: Schema,
    /// The spec on which the type is based.
    readonly spec: MarkSpec
  ) {
    this.attrs = initAttrs(name, spec.attrs)
    ;(this as any).excluded = null
    let defaults = defaultAttrs(this.attrs)
    this.instance = defaults ? new Mark(this, defaults) : null
  }

  /// Create a mark of this type. `attrs` may be `null` or an object
  /// containing only some of the mark's attributes. The others, if
  /// they have defaults, will be added.
  create(attrs: Attrs | null = null) {
    if (!attrs && this.instance) return this.instance
    return new Mark(this, computeAttrs(this.attrs, attrs))
  }

  /// @internal
  static compile(marks: OrderedMap<MarkSpec>, schema: Schema) {
    let result = Object.create(null), rank = 0
    marks.forEach((name, spec) => result[name] = new MarkType(name, rank++, schema, spec))
    return result
  }

  /// When there is a mark of this type in the given set, a new set
  /// without it is returned. Otherwise, the input set is returned.
  removeFromSet(set: readonly Mark[]): readonly Mark[] {
    for (var i = 0; i < set.length; i++) if (set[i].type == this) {
      set = set.slice(0, i).concat(set.slice(i + 1))
      i--
    }
    return set
  }

  /// Tests whether there is a mark of this type in the given set.
  isInSet(set: readonly Mark[]): Mark | undefined {
    for (let i = 0; i < set.length; i++)
      if (set[i].type == this) return set[i]
  }

  /// @internal
  checkAttrs(attrs: Attrs) {
    checkAttrs(this.attrs, attrs, "mark", this.name)
  }

  /// Queries whether a given mark type is
  /// [excluded](#model.MarkSpec.excludes) by this one.
  excludes(other: MarkType) {
    return this.excluded.indexOf(other) > -1
  }
}

/// An object describing a schema, as passed to the [`Schema`](#model.Schema)
/// constructor.
export interface SchemaSpec<Nodes extends string = any, Marks extends string = any> {
  /// The node types in this schema. Maps names to
  /// [`NodeSpec`](#model.NodeSpec) objects that describe the node type
  /// associated with that name. Their order is significant—it
  /// determines which [parse rules](#model.NodeSpec.parseDOM) take
  /// precedence by default, and which nodes come first in a given
  /// [group](#model.NodeSpec.group).
  nodes: {[name in Nodes]: NodeSpec} | OrderedMap<NodeSpec>,

  /// The mark types that exist in this schema. The order in which they
  /// are provided determines the order in which [mark
  /// sets](#model.Mark.addToSet) are sorted and in which [parse
  /// rules](#model.MarkSpec.parseDOM) are tried.
  marks?: {[name in Marks]: MarkSpec} | OrderedMap<MarkSpec>

  /// The name of the default top-level node for the schema. Defaults
  /// to `"doc"`.
  topNode?: string
}

/// A description of a node type, used when defining a schema.
export interface NodeSpec {
  /// The content expression for this node, as described in the [schema
  /// guide](/docs/guide/#schema.content_expressions). When not given,
  /// the node does not allow any content.
  content?: string

  /// The marks that are allowed inside of this node. May be a
  /// space-separated string referring to mark names or groups, `"_"`
  /// to explicitly allow all marks, or `""` to disallow marks. When
  /// not given, nodes with inline content default to allowing all
  /// marks, other nodes default to not allowing marks.
  marks?: string

  /// The group or space-separated groups to which this node belongs,
  /// which can be referred to in the content expressions for the
  /// schema.
  group?: string

  /// Should be set to true for inline nodes. (Implied for text nodes.)
  inline?: boolean

  /// Can be set to true to indicate that, though this isn't a [leaf
  /// node](#model.NodeType.isLeaf), it doesn't have directly editable
  /// content and should be treated as a single unit in the view.
  atom?: boolean

  /// The attributes that nodes of this type get.
  attrs?: {[name: string]: AttributeSpec}

  /// Controls whether nodes of this type can be selected as a [node
  /// selection](#state.NodeSelection). Defaults to true for non-text
  /// nodes.
  selectable?: boolean

  /// Determines whether nodes of this type can be dragged without
  /// being selected. Defaults to false.
  draggable?: boolean

  /// Can be used to indicate that this node contains code, which
  /// causes some commands to behave differently.
  code?: boolean

  /// Controls way whitespace in this a node is parsed. The default is
  /// `"normal"`, which causes the [DOM parser](#model.DOMParser) to
  /// collapse whitespace in normal mode, and normalize it (replacing
  /// newlines and such with spaces) otherwise. `"pre"` causes the
  /// parser to preserve spaces inside the node. When this option isn't
  /// given, but [`code`](#model.NodeSpec.code) is true, `whitespace`
  /// will default to `"pre"`. Note that this option doesn't influence
  /// the way the node is rendered—that should be handled by `toDOM`
  /// and/or styling.
  whitespace?: "pre" | "normal"

  /// Determines whether this node is considered an important parent
  /// node during replace operations (such as paste). Non-defining (the
  /// default) nodes get dropped when their entire content is replaced,
  /// whereas defining nodes persist and wrap the inserted content.
  definingAsContext?: boolean

  /// In inserted content the defining parents of the content are
  /// preserved when possible. Typically, non-default-paragraph
  /// textblock types, and possibly list items, are marked as defining.
  definingForContent?: boolean

  /// When enabled, enables both
  /// [`definingAsContext`](#model.NodeSpec.definingAsContext) and
  /// [`definingForContent`](#model.NodeSpec.definingForContent).
  defining?: boolean

  /// When enabled (default is false), the sides of nodes of this type
  /// count as boundaries that regular editing operations, like
  /// backspacing or lifting, won't cross. An example of a node that
  /// should probably have this enabled is a table cell.
  isolating?: boolean

  /// Defines the default way a node of this type should be serialized
  /// to DOM/HTML (as used by
  /// [`DOMSerializer.fromSchema`](#model.DOMSerializer^fromSchema)).
  /// Should return a DOM node or an [array
  /// structure](#model.DOMOutputSpec) that describes one, with an
  /// optional number zero (“hole”) in it to indicate where the node's
  /// content should be inserted.
  ///
  /// For text nodes, the default is to create a text DOM node. Though
  /// it is possible to create a serializer where text is rendered
  /// differently, this is not supported inside the editor, so you
  /// shouldn't override that in your text node spec.
  toDOM?: (node: Node) => DOMOutputSpec

  /// Associates DOM parser information with this node, which can be
  /// used by [`DOMParser.fromSchema`](#model.DOMParser^fromSchema) to
  /// automatically derive a parser. The `node` field in the rules is
  /// implied (the name of this node will be filled in automatically).
  /// If you supply your own parser, you do not need to also specify
  /// parsing rules in your schema.
  parseDOM?: readonly TagParseRule[]

  /// Defines the default way a node of this type should be serialized
  /// to a string representation for debugging (e.g. in error messages).
  toDebugString?: (node: Node) => string

  /// Defines the default way a [leaf node](#model.NodeType.isLeaf) of
  /// this type should be serialized to a string (as used by
  /// [`Node.textBetween`](#model.Node^textBetween) and
  /// [`Node.textContent`](#model.Node^textContent)).
  leafText?: (node: Node) => string

  /// A single inline node in a schema can be set to be a linebreak
  /// equivalent. When converting between block types that support the
  /// node and block types that don't but have
  /// [`whitespace`](#model.NodeSpec.whitespace) set to `"pre"`,
  /// [`setBlockType`](#transform.Transform.setBlockType) will convert
  /// between newline characters to or from linebreak nodes as
  /// appropriate.
  linebreakReplacement?: boolean

  /// Node specs may include arbitrary properties that can be read by
  /// other code via [`NodeType.spec`](#model.NodeType.spec).
  [key: string]: any
}

/// Used to define marks when creating a schema.
export interface MarkSpec {
  /// The attributes that marks of this type get.
  attrs?: {[name: string]: AttributeSpec}

  /// Whether this mark should be active when the cursor is positioned
  /// at its end (or at its start when that is also the start of the
  /// parent node). Defaults to true.
  inclusive?: boolean

  /// Determines which other marks this mark can coexist with. Should
  /// be a space-separated strings naming other marks or groups of marks.
  /// When a mark is [added](#model.Mark.addToSet) to a set, all marks
  /// that it excludes are removed in the process. If the set contains
  /// any mark that excludes the new mark but is not, itself, excluded
  /// by the new mark, the mark can not be added an the set. You can
  /// use the value `"_"` to indicate that the mark excludes all
  /// marks in the schema.
  ///
  /// Defaults to only being exclusive with marks of the same type. You
  /// can set it to an empty string (or any string not containing the
  /// mark's own name) to allow multiple marks of a given type to
  /// coexist (as long as they have different attributes).
  excludes?: string

  /// The group or space-separated groups to which this mark belongs.
  group?: string

  /// Determines whether marks of this type can span multiple adjacent
  /// nodes when serialized to DOM/HTML. Defaults to true.
  spanning?: boolean

  /// Defines the default way marks of this type should be serialized
  /// to DOM/HTML. When the resulting spec contains a hole, that is
  /// where the marked content is placed. Otherwise, it is appended to
  /// the top node.
  toDOM?: (mark: Mark, inline: boolean) => DOMOutputSpec

  /// Associates DOM parser information with this mark (see the
  /// corresponding [node spec field](#model.NodeSpec.parseDOM)). The
  /// `mark` field in the rules is implied.
  parseDOM?: readonly ParseRule[]

  /// Mark specs can include additional properties that can be
  /// inspected through [`MarkType.spec`](#model.MarkType.spec) when
  /// working with the mark.
  [key: string]: any
}

/// Used to [define](#model.NodeSpec.attrs) attributes on nodes or
/// marks.
export interface AttributeSpec {
  /// The default value for this attribute, to use when no explicit
  /// value is provided. Attributes that have no default must be
  /// provided whenever a node or mark of a type that has them is
  /// created.
  default?: any
  /// A function or type name used to validate values of this
  /// attribute. This will be used when deserializing the attribute
  /// from JSON, and when running [`Node.check`](#model.Node.check).
  /// When a function, it should raise an exception if the value isn't
  /// of the expected type or shape. When a string, it should be a
  /// `|`-separated string of primitive types (`"number"`, `"string"`,
  /// `"boolean"`, `"null"`, and `"undefined"`), and the library will
  /// raise an error when the value is not one of those types.
  validate?: string | ((value: any) => void)
}

/// A document schema. Holds [node](#model.NodeType) and [mark
/// type](#model.MarkType) objects for the nodes and marks that may
/// occur in conforming documents, and provides functionality for
/// creating and deserializing such documents.
///
/// When given, the type parameters provide the names of the nodes and
/// marks in this schema.
export class Schema<Nodes extends string = any, Marks extends string = any> {
  /// The [spec](#model.SchemaSpec) on which the schema is based,
  /// with the added guarantee that its `nodes` and `marks`
  /// properties are
  /// [`OrderedMap`](https://github.com/marijnh/orderedmap) instances
  /// (not raw objects).
  spec: {
    nodes: OrderedMap<NodeSpec>,
    marks: OrderedMap<MarkSpec>,
    topNode?: string
  }

  /// An object mapping the schema's node names to node type objects.
  nodes: {readonly [name in Nodes]: NodeType} & {readonly [key: string]: NodeType}

  /// A map from mark names to mark type objects.
  marks: {readonly [name in Marks]: MarkType} & {readonly [key: string]: MarkType}

  /// The [linebreak
  /// replacement](#model.NodeSpec.linebreakReplacement) node defined
  /// in this schema, if any.
  linebreakReplacement: NodeType | null = null

  /// Construct a schema from a schema [specification](#model.SchemaSpec).
  constructor(spec: SchemaSpec<Nodes, Marks>) {
    let instanceSpec = this.spec = {} as any
    for (let prop in spec) instanceSpec[prop] = (spec as any)[prop]
    instanceSpec.nodes = OrderedMap.from(spec.nodes),
    instanceSpec.marks = OrderedMap.from(spec.marks || {}),

    this.nodes = NodeType.compile(this.spec.nodes, this)
    this.marks = MarkType.compile(this.spec.marks, this)

    let contentExprCache = Object.create(null)
    for (let prop in this.nodes) {
      if (prop in this.marks)
        throw new RangeError(prop + " can not be both a node and a mark")
      let type = this.nodes[prop], contentExpr = type.spec.content || "", markExpr = type.spec.marks
      type.contentMatch = contentExprCache[contentExpr] ||
        (contentExprCache[contentExpr] = ContentMatch.parse(contentExpr, this.nodes))
      ;(type as any).inlineContent = type.contentMatch.inlineContent
      if (type.spec.linebreakReplacement) {
        if (this.linebreakReplacement) throw new RangeError("Multiple linebreak nodes defined")
        if (!type.isInline || !type.isLeaf) throw new RangeError("Linebreak replacement nodes must be inline leaf nodes")
        this.linebreakReplacement = type
      }
      type.markSet = markExpr == "_" ? null :
        markExpr ? gatherMarks(this, markExpr.split(" ")) :
        markExpr == "" || !type.inlineContent ? [] : null
    }
    for (let prop in this.marks) {
      let type = this.marks[prop], excl = type.spec.excludes
      type.excluded = excl == null ? [type] : excl == "" ? [] : gatherMarks(this, excl.split(" "))
    }

    this.nodeFromJSON = this.nodeFromJSON.bind(this)
    this.markFromJSON = this.markFromJSON.bind(this)
    this.topNodeType = this.nodes[this.spec.topNode || "doc"]
    this.cached.wrappings = Object.create(null)
  }

  /// The type of the [default top node](#model.SchemaSpec.topNode)
  /// for this schema.
  topNodeType: NodeType

  /// An object for storing whatever values modules may want to
  /// compute and cache per schema. (If you want to store something
  /// in it, try to use property names unlikely to clash.)
  cached: {[key: string]: any} = Object.create(null)

  /// Create a node in this schema. The `type` may be a string or a
  /// `NodeType` instance. Attributes will be extended with defaults,
  /// `content` may be a `Fragment`, `null`, a `Node`, or an array of
  /// nodes.
  node(type: string | NodeType,
       attrs: Attrs | null = null,
       content?: Fragment | Node | readonly Node[],
       marks?: readonly Mark[]) {
    if (typeof type == "string")
      type = this.nodeType(type)
    else if (!(type instanceof NodeType))
      throw new RangeError("Invalid node type: " + type)
    else if (type.schema != this)
      throw new RangeError("Node type from different schema used (" + type.name + ")")

    return type.createChecked(attrs, content, marks)
  }

  /// Create a text node in the schema. Empty text nodes are not
  /// allowed.
  text(text: string, marks?: readonly Mark[] | null): Node {
    let type = this.nodes.text
    return new TextNode(type, type.defaultAttrs, text, Mark.setFrom(marks))
  }

  /// Create a mark with the given type and attributes.
  mark(type: string | MarkType, attrs?: Attrs | null) {
    if (typeof type == "string") type = this.marks[type]
    return type.create(attrs)
  }

  /// Deserialize a node from its JSON representation. This method is
  /// bound.
  nodeFromJSON(json: any): Node {
    return Node.fromJSON(this, json)
  }

  /// Deserialize a mark from its JSON representation. This method is
  /// bound.
  markFromJSON(json: any): Mark {
    return Mark.fromJSON(this, json)
  }

  /// @internal
  nodeType(name: string) {
    let found = this.nodes[name]
    if (!found) throw new RangeError("Unknown node type: " + name)
    return found
  }
}

function gatherMarks(schema: Schema, marks: readonly string[]) {
  let found: MarkType[] = []
  for (let i = 0; i < marks.length; i++) {
    let name = marks[i], mark = schema.marks[name], ok = mark
    if (mark) {
      found.push(mark)
    } else {
      for (let prop in schema.marks) {
        let mark = schema.marks[prop]
        if (name == "_" || (mark.spec.group && mark.spec.group.split(" ").indexOf(name) > -1))
          found.push(ok = mark)
      }
    }
    if (!ok) throw new SyntaxError("Unknown mark type: '" + marks[i] + "'")
  }
  return found
}
