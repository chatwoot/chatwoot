import {Fragment} from "./fragment"
import {Slice} from "./replace"
import {Mark} from "./mark"
import {Node, TextNode} from "./node"
import {ContentMatch} from "./content"
import {ResolvedPos} from "./resolvedpos"
import {Schema, Attrs, NodeType, MarkType} from "./schema"
import {DOMNode} from "./dom"

/// These are the options recognized by the
/// [`parse`](#model.DOMParser.parse) and
/// [`parseSlice`](#model.DOMParser.parseSlice) methods.
export interface ParseOptions {
  /// By default, whitespace is collapsed as per HTML's rules. Pass
  /// `true` to preserve whitespace, but normalize newlines to
  /// spaces, and `"full"` to preserve whitespace entirely.
  preserveWhitespace?: boolean | "full"

  /// When given, the parser will, beside parsing the content,
  /// record the document positions of the given DOM positions. It
  /// will do so by writing to the objects, adding a `pos` property
  /// that holds the document position. DOM positions that are not
  /// in the parsed content will not be written to.
  findPositions?: {node: DOMNode, offset: number, pos?: number}[]

  /// The child node index to start parsing from.
  from?: number

  /// The child node index to stop parsing at.
  to?: number

  /// By default, the content is parsed into the schema's default
  /// [top node type](#model.Schema.topNodeType). You can pass this
  /// option to use the type and attributes from a different node
  /// as the top container.
  topNode?: Node

  /// Provide the starting content match that content parsed into the
  /// top node is matched against.
  topMatch?: ContentMatch

  /// A set of additional nodes to count as
  /// [context](#model.ParseRule.context) when parsing, above the
  /// given [top node](#model.ParseOptions.topNode).
  context?: ResolvedPos

  /// @internal
  ruleFromNode?: (node: DOMNode) => Omit<TagParseRule, "tag"> | null
  /// @internal
  topOpen?: boolean
}

/// Fields that may be present in both [tag](#model.TagParseRule) and
/// [style](#model.StyleParseRule) parse rules.
export interface GenericParseRule {
  /// Can be used to change the order in which the parse rules in a
  /// schema are tried. Those with higher priority come first. Rules
  /// without a priority are counted as having priority 50. This
  /// property is only meaningful in a schema—when directly
  /// constructing a parser, the order of the rule array is used.
  priority?: number

  /// By default, when a rule matches an element or style, no further
  /// rules get a chance to match it. By setting this to `false`, you
  /// indicate that even when this rule matches, other rules that come
  /// after it should also run.
  consuming?: boolean

  /// When given, restricts this rule to only match when the current
  /// context—the parent nodes into which the content is being
  /// parsed—matches this expression. Should contain one or more node
  /// names or node group names followed by single or double slashes.
  /// For example `"paragraph/"` means the rule only matches when the
  /// parent node is a paragraph, `"blockquote/paragraph/"` restricts
  /// it to be in a paragraph that is inside a blockquote, and
  /// `"section//"` matches any position inside a section—a double
  /// slash matches any sequence of ancestor nodes. To allow multiple
  /// different contexts, they can be separated by a pipe (`|`)
  /// character, as in `"blockquote/|list_item/"`.
  context?: string

  /// The name of the mark type to wrap the matched content in.
  mark?: string

  /// When true, ignore content that matches this rule.
  ignore?: boolean

  /// When true, finding an element that matches this rule will close
  /// the current node.
  closeParent?: boolean

  /// When true, ignore the node that matches this rule, but do parse
  /// its content.
  skip?: boolean

  /// Attributes for the node or mark created by this rule. When
  /// `getAttrs` is provided, it takes precedence.
  attrs?: Attrs
}

/// Parse rule targeting a DOM element.
export interface TagParseRule extends GenericParseRule {
  /// A CSS selector describing the kind of DOM elements to match.
  tag: string

  /// The namespace to match. Nodes are only matched when the
  /// namespace matches or this property is null.
  namespace?: string

  /// The name of the node type to create when this rule matches. Each
  /// rule should have either a `node`, `mark`, or `ignore` property
  /// (except when it appears in a [node](#model.NodeSpec.parseDOM) or
  /// [mark spec](#model.MarkSpec.parseDOM), in which case the `node`
  /// or `mark` property will be derived from its position).
  node?: string

  /// A function used to compute the attributes for the node or mark
  /// created by this rule. Can also be used to describe further
  /// conditions the DOM element or style must match. When it returns
  /// `false`, the rule won't match. When it returns null or undefined,
  /// that is interpreted as an empty/default set of attributes.
  getAttrs?: (node: HTMLElement) => Attrs | false | null

  /// For rules that produce non-leaf nodes, by default the content of
  /// the DOM element is parsed as content of the node. If the child
  /// nodes are in a descendent node, this may be a CSS selector
  /// string that the parser must use to find the actual content
  /// element, or a function that returns the actual content element
  /// to the parser.
  contentElement?: string | HTMLElement | ((node: DOMNode) => HTMLElement)

  /// Can be used to override the content of a matched node. When
  /// present, instead of parsing the node's child nodes, the result of
  /// this function is used.
  getContent?: (node: DOMNode, schema: Schema) => Fragment

  /// Controls whether whitespace should be preserved when parsing the
  /// content inside the matched element. `false` means whitespace may
  /// be collapsed, `true` means that whitespace should be preserved
  /// but newlines normalized to spaces, and `"full"` means that
  /// newlines should also be preserved.
  preserveWhitespace?: boolean | "full"
}

/// A parse rule targeting a style property.
export interface StyleParseRule extends GenericParseRule {
  /// A CSS property name to match. This rule will match inline styles
  /// that list that property. May also have the form
  /// `"property=value"`, in which case the rule only matches if the
  /// property's value exactly matches the given value. (For more
  /// complicated filters, use [`getAttrs`](#model.ParseRule.getAttrs)
  /// and return false to indicate that the match failed.) Rules
  /// matching styles may only produce [marks](#model.ParseRule.mark),
  /// not nodes.
  style: string

  /// Given to make TS see ParseRule as a tagged union @hide
  tag?: undefined

  /// Style rules can remove marks from the set of active marks.
  clearMark?: (mark: Mark) => boolean

  /// A function used to compute the attributes for the node or mark
  /// created by this rule. Called with the style's value.
  getAttrs?: (node: string) => Attrs | false | null
}

/// A value that describes how to parse a given DOM node or inline
/// style as a ProseMirror node or mark.
export type ParseRule = TagParseRule | StyleParseRule

function isTagRule(rule: ParseRule): rule is TagParseRule { return (rule as TagParseRule).tag != null }
function isStyleRule(rule: ParseRule): rule is StyleParseRule { return (rule as StyleParseRule).style != null }

/// A DOM parser represents a strategy for parsing DOM content into a
/// ProseMirror document conforming to a given schema. Its behavior is
/// defined by an array of [rules](#model.ParseRule).
export class DOMParser {
  /// @internal
  tags: TagParseRule[] = []
  /// @internal
  styles: StyleParseRule[] = []
  /// @internal
  matchedStyles: readonly string[]
  /// @internal
  normalizeLists: boolean

  /// Create a parser that targets the given schema, using the given
  /// parsing rules.
  constructor(
    /// The schema into which the parser parses.
    readonly schema: Schema,
    /// The set of [parse rules](#model.ParseRule) that the parser
    /// uses, in order of precedence.
    readonly rules: readonly ParseRule[]
  ) {
    let matchedStyles: string[] = this.matchedStyles = []
    rules.forEach(rule => {
      if (isTagRule(rule)) {
        this.tags.push(rule)
      } else if (isStyleRule(rule)) {
        let prop = /[^=]*/.exec(rule.style)![0]
        if (matchedStyles.indexOf(prop) < 0) matchedStyles.push(prop)
        this.styles.push(rule)
      }
    })

    // Only normalize list elements when lists in the schema can't directly contain themselves
    this.normalizeLists = !this.tags.some(r => {
      if (!/^(ul|ol)\b/.test(r.tag!) || !r.node) return false
      let node = schema.nodes[r.node]
      return node.contentMatch.matchType(node)
    })
  }

  /// Parse a document from the content of a DOM node.
  parse(dom: DOMNode, options: ParseOptions = {}): Node {
    let context = new ParseContext(this, options, false)
    context.addAll(dom, Mark.none, options.from, options.to)
    return context.finish() as Node
  }

  /// Parses the content of the given DOM node, like
  /// [`parse`](#model.DOMParser.parse), and takes the same set of
  /// options. But unlike that method, which produces a whole node,
  /// this one returns a slice that is open at the sides, meaning that
  /// the schema constraints aren't applied to the start of nodes to
  /// the left of the input and the end of nodes at the end.
  parseSlice(dom: DOMNode, options: ParseOptions = {}) {
    let context = new ParseContext(this, options, true)
    context.addAll(dom, Mark.none, options.from, options.to)
    return Slice.maxOpen(context.finish() as Fragment)
  }

  /// @internal
  matchTag(dom: DOMNode, context: ParseContext, after?: TagParseRule) {
    for (let i = after ? this.tags.indexOf(after) + 1 : 0; i < this.tags.length; i++) {
      let rule = this.tags[i]
      if (matches(dom, rule.tag!) &&
          (rule.namespace === undefined || (dom as HTMLElement).namespaceURI == rule.namespace) &&
          (!rule.context || context.matchesContext(rule.context))) {
        if (rule.getAttrs) {
          let result = rule.getAttrs(dom as HTMLElement)
          if (result === false) continue
          rule.attrs = result || undefined
        }
        return rule
      }
    }
  }

  /// @internal
  matchStyle(prop: string, value: string, context: ParseContext, after?: StyleParseRule) {
    for (let i = after ? this.styles.indexOf(after) + 1 : 0; i < this.styles.length; i++) {
      let rule = this.styles[i], style = rule.style!
      if (style.indexOf(prop) != 0 ||
          rule.context && !context.matchesContext(rule.context) ||
          // Test that the style string either precisely matches the prop,
          // or has an '=' sign after the prop, followed by the given
          // value.
          style.length > prop.length &&
          (style.charCodeAt(prop.length) != 61 || style.slice(prop.length + 1) != value))
        continue
      if (rule.getAttrs) {
        let result = rule.getAttrs(value)
        if (result === false) continue
        rule.attrs = result || undefined
      }
      return rule
    }
  }

  /// @internal
  static schemaRules(schema: Schema) {
    let result: ParseRule[] = []
    function insert(rule: ParseRule) {
      let priority = rule.priority == null ? 50 : rule.priority, i = 0
      for (; i < result.length; i++) {
        let next = result[i], nextPriority = next.priority == null ? 50 : next.priority
        if (nextPriority < priority) break
      }
      result.splice(i, 0, rule)
    }

    for (let name in schema.marks) {
      let rules = schema.marks[name].spec.parseDOM
      if (rules) rules.forEach(rule => {
        insert(rule = copy(rule) as ParseRule)
        if (!(rule.mark || rule.ignore || (rule as StyleParseRule).clearMark))
          rule.mark = name
      })
    }
    for (let name in schema.nodes) {
      let rules = schema.nodes[name].spec.parseDOM
      if (rules) rules.forEach(rule => {
        insert(rule = copy(rule) as TagParseRule)
        if (!((rule as TagParseRule).node || rule.ignore || rule.mark))
          rule.node = name
      })
    }
    return result
  }

  /// Construct a DOM parser using the parsing rules listed in a
  /// schema's [node specs](#model.NodeSpec.parseDOM), reordered by
  /// [priority](#model.ParseRule.priority).
  static fromSchema(schema: Schema) {
    return schema.cached.domParser as DOMParser ||
      (schema.cached.domParser = new DOMParser(schema, DOMParser.schemaRules(schema)))
  }
}

const blockTags: {[tagName: string]: boolean} = {
  address: true, article: true, aside: true, blockquote: true, canvas: true,
  dd: true, div: true, dl: true, fieldset: true, figcaption: true, figure: true,
  footer: true, form: true, h1: true, h2: true, h3: true, h4: true, h5: true,
  h6: true, header: true, hgroup: true, hr: true, li: true, noscript: true, ol: true,
  output: true, p: true, pre: true, section: true, table: true, tfoot: true, ul: true
}

const ignoreTags: {[tagName: string]: boolean} = {
  head: true, noscript: true, object: true, script: true, style: true, title: true
}

const listTags: {[tagName: string]: boolean} = {ol: true, ul: true}

// Using a bitfield for node context options
const OPT_PRESERVE_WS = 1, OPT_PRESERVE_WS_FULL = 2, OPT_OPEN_LEFT = 4

function wsOptionsFor(type: NodeType | null, preserveWhitespace: boolean | "full" | undefined, base: number) {
  if (preserveWhitespace != null) return (preserveWhitespace ? OPT_PRESERVE_WS : 0) |
    (preserveWhitespace === "full" ? OPT_PRESERVE_WS_FULL : 0)
  return type && type.whitespace == "pre" ? OPT_PRESERVE_WS | OPT_PRESERVE_WS_FULL : base & ~OPT_OPEN_LEFT
}

class NodeContext {
  match: ContentMatch | null
  content: Node[] = []

  // Marks applied to the node's children
  activeMarks: readonly Mark[] = Mark.none

  constructor(
    readonly type: NodeType | null,
    readonly attrs: Attrs | null,
    readonly marks: readonly Mark[],
    readonly solid: boolean,
    match: ContentMatch | null,
    readonly options: number
  ) {
    this.match = match || (options & OPT_OPEN_LEFT ? null : type!.contentMatch)
  }

  findWrapping(node: Node) {
    if (!this.match) {
      if (!this.type) return []
      let fill = this.type.contentMatch.fillBefore(Fragment.from(node))
      if (fill) {
        this.match = this.type.contentMatch.matchFragment(fill)!
      } else {
        let start = this.type.contentMatch, wrap
        if (wrap = start.findWrapping(node.type)) {
          this.match = start
          return wrap
        } else {
          return null
        }
      }
    }
    return this.match.findWrapping(node.type)
  }

  finish(openEnd?: boolean): Node | Fragment {
    if (!(this.options & OPT_PRESERVE_WS)) { // Strip trailing whitespace
      let last = this.content[this.content.length - 1], m
      if (last && last.isText && (m = /[ \t\r\n\u000c]+$/.exec(last.text!))) {
        let text = last as TextNode
        if (last.text!.length == m[0].length) this.content.pop()
        else this.content[this.content.length - 1] = text.withText(text.text.slice(0, text.text.length - m[0].length))
      }
    }
    let content = Fragment.from(this.content)
    if (!openEnd && this.match)
      content = content.append(this.match.fillBefore(Fragment.empty, true)!)
    return this.type ? this.type.create(this.attrs, content, this.marks) : content
  }

  inlineContext(node: DOMNode) {
    if (this.type) return this.type.inlineContent
    if (this.content.length) return this.content[0].isInline
    return node.parentNode && !blockTags.hasOwnProperty(node.parentNode.nodeName.toLowerCase())
  }
}

class ParseContext {
  open: number = 0
  find: {node: DOMNode, offset: number, pos?: number}[] | undefined
  needsBlock: boolean
  nodes: NodeContext[]

  constructor(
    // The parser we are using.
    readonly parser: DOMParser,
    // The options passed to this parse.
    readonly options: ParseOptions,
    readonly isOpen: boolean
  ) {
    let topNode = options.topNode, topContext: NodeContext
    let topOptions = wsOptionsFor(null, options.preserveWhitespace, 0) | (isOpen ? OPT_OPEN_LEFT : 0)
    if (topNode)
      topContext = new NodeContext(topNode.type, topNode.attrs, Mark.none, true,
                                   options.topMatch || topNode.type.contentMatch, topOptions)
    else if (isOpen)
      topContext = new NodeContext(null, null, Mark.none, true, null, topOptions)
    else
      topContext = new NodeContext(parser.schema.topNodeType, null, Mark.none, true, null, topOptions)
    this.nodes = [topContext]
    this.find = options.findPositions
    this.needsBlock = false
  }

  get top() {
    return this.nodes[this.open]
  }

  // Add a DOM node to the content. Text is inserted as text node,
  // otherwise, the node is passed to `addElement` or, if it has a
  // `style` attribute, `addElementWithStyles`.
  addDOM(dom: DOMNode, marks: readonly Mark[]) {
    if (dom.nodeType == 3) this.addTextNode(dom as Text, marks)
    else if (dom.nodeType == 1) this.addElement(dom as HTMLElement, marks)
  }

  addTextNode(dom: Text, marks: readonly Mark[]) {
    let value = dom.nodeValue!
    let top = this.top
    if (top.options & OPT_PRESERVE_WS_FULL ||
        top.inlineContext(dom) ||
        /[^ \t\r\n\u000c]/.test(value)) {
      if (!(top.options & OPT_PRESERVE_WS)) {
        value = value.replace(/[ \t\r\n\u000c]+/g, " ")
        // If this starts with whitespace, and there is no node before it, or
        // a hard break, or a text node that ends with whitespace, strip the
        // leading space.
        if (/^[ \t\r\n\u000c]/.test(value) && this.open == this.nodes.length - 1) {
          let nodeBefore = top.content[top.content.length - 1]
          let domNodeBefore = dom.previousSibling
          if (!nodeBefore ||
              (domNodeBefore && domNodeBefore.nodeName == 'BR') ||
              (nodeBefore.isText && /[ \t\r\n\u000c]$/.test(nodeBefore.text!)))
            value = value.slice(1)
        }
      } else if (!(top.options & OPT_PRESERVE_WS_FULL)) {
        value = value.replace(/\r?\n|\r/g, " ")
      } else {
        value = value.replace(/\r\n?/g, "\n")
      }
      if (value) this.insertNode(this.parser.schema.text(value), marks)
      this.findInText(dom)
    } else {
      this.findInside(dom)
    }
  }

  // Try to find a handler for the given tag and use that to parse. If
  // none is found, the element's content nodes are added directly.
  addElement(dom: HTMLElement, marks: readonly Mark[], matchAfter?: TagParseRule) {
    let name = dom.nodeName.toLowerCase(), ruleID: TagParseRule | undefined
    if (listTags.hasOwnProperty(name) && this.parser.normalizeLists) normalizeList(dom)
    let rule = (this.options.ruleFromNode && this.options.ruleFromNode(dom)) ||
        (ruleID = this.parser.matchTag(dom, this, matchAfter))
    if (rule ? rule.ignore : ignoreTags.hasOwnProperty(name)) {
      this.findInside(dom)
      this.ignoreFallback(dom, marks)
    } else if (!rule || rule.skip || rule.closeParent) {
      if (rule && rule.closeParent) this.open = Math.max(0, this.open - 1)
      else if (rule && (rule.skip as any).nodeType) dom = rule.skip as any as HTMLElement
      let sync, top = this.top, oldNeedsBlock = this.needsBlock
      if (blockTags.hasOwnProperty(name)) {
        if (top.content.length && top.content[0].isInline && this.open) {
          this.open--
          top = this.top
        }
        sync = true
        if (!top.type) this.needsBlock = true
      } else if (!dom.firstChild) {
        this.leafFallback(dom, marks)
        return
      }
      let innerMarks = rule && rule.skip ? marks : this.readStyles(dom, marks)
      if (innerMarks) this.addAll(dom, innerMarks)
      if (sync) this.sync(top)
      this.needsBlock = oldNeedsBlock
    } else {
      let innerMarks = this.readStyles(dom, marks)
      if (innerMarks)
        this.addElementByRule(dom, rule as TagParseRule, innerMarks, rule!.consuming === false ? ruleID : undefined)
    }
  }

  // Called for leaf DOM nodes that would otherwise be ignored
  leafFallback(dom: DOMNode, marks: readonly Mark[]) {
    if (dom.nodeName == "BR" && this.top.type && this.top.type.inlineContent)
      this.addTextNode(dom.ownerDocument!.createTextNode("\n"), marks)
  }

  // Called for ignored nodes
  ignoreFallback(dom: DOMNode, marks: readonly Mark[]) {
    // Ignored BR nodes should at least create an inline context
    if (dom.nodeName == "BR" && (!this.top.type || !this.top.type.inlineContent))
      this.findPlace(this.parser.schema.text("-"), marks)
  }

  // Run any style parser associated with the node's styles. Either
  // return an updated array of marks, or null to indicate some of the
  // styles had a rule with `ignore` set.
  readStyles(dom: HTMLElement, marks: readonly Mark[]) {
    let styles = dom.style
    // Because many properties will only show up in 'normalized' form
    // in `style.item` (i.e. text-decoration becomes
    // text-decoration-line, text-decoration-color, etc), we directly
    // query the styles mentioned in our rules instead of iterating
    // over the items.
    if (styles && styles.length) for (let i = 0; i < this.parser.matchedStyles.length; i++) {
      let name = this.parser.matchedStyles[i], value = styles.getPropertyValue(name)
      if (value) for (let after: StyleParseRule | undefined = undefined;;) {
        let rule = this.parser.matchStyle(name, value, this, after)
        if (!rule) break
        if (rule.ignore) return null
        if (rule.clearMark)
          marks = marks.filter(m => !rule!.clearMark!(m))
        else
          marks = marks.concat(this.parser.schema.marks[rule.mark!].create(rule.attrs))
        if (rule.consuming === false) after = rule
        else break
      }
    }
    return marks
  }

  // Look up a handler for the given node. If none are found, return
  // false. Otherwise, apply it, use its return value to drive the way
  // the node's content is wrapped, and return true.
  addElementByRule(dom: HTMLElement, rule: TagParseRule, marks: readonly Mark[], continueAfter?: TagParseRule) {
    let sync, nodeType
    if (rule.node) {
      nodeType = this.parser.schema.nodes[rule.node]
      if (!nodeType.isLeaf) {
        let inner = this.enter(nodeType, rule.attrs || null, marks, rule.preserveWhitespace)
        if (inner) {
          sync = true
          marks = inner
        }
      } else if (!this.insertNode(nodeType.create(rule.attrs), marks)) {
        this.leafFallback(dom, marks)
      }
    } else {
      let markType = this.parser.schema.marks[rule.mark!]
      marks = marks.concat(markType.create(rule.attrs))
    }
    let startIn = this.top

    if (nodeType && nodeType.isLeaf) {
      this.findInside(dom)
    } else if (continueAfter) {
      this.addElement(dom, marks, continueAfter)
    } else if (rule.getContent) {
      this.findInside(dom)
      rule.getContent(dom, this.parser.schema).forEach(node => this.insertNode(node, marks))
    } else {
      let contentDOM = dom
      if (typeof rule.contentElement == "string") contentDOM = dom.querySelector(rule.contentElement)!
      else if (typeof rule.contentElement == "function") contentDOM = rule.contentElement(dom)
      else if (rule.contentElement) contentDOM = rule.contentElement
      this.findAround(dom, contentDOM, true)
      this.addAll(contentDOM, marks)
    }
    if (sync && this.sync(startIn)) this.open--
  }

  // Add all child nodes between `startIndex` and `endIndex` (or the
  // whole node, if not given). If `sync` is passed, use it to
  // synchronize after every block element.
  addAll(parent: DOMNode, marks: readonly Mark[], startIndex?: number, endIndex?: number) {
    let index = startIndex || 0
    for (let dom = startIndex ? parent.childNodes[startIndex] : parent.firstChild,
             end = endIndex == null ? null : parent.childNodes[endIndex];
         dom != end; dom = dom!.nextSibling, ++index) {
      this.findAtPoint(parent, index)
      this.addDOM(dom!, marks)
    }
    this.findAtPoint(parent, index)
  }

  // Try to find a way to fit the given node type into the current
  // context. May add intermediate wrappers and/or leave non-solid
  // nodes that we're in.
  findPlace(node: Node, marks: readonly Mark[]) {
    let route, sync: NodeContext | undefined
    for (let depth = this.open; depth >= 0; depth--) {
      let cx = this.nodes[depth]
      let found = cx.findWrapping(node)
      if (found && (!route || route.length > found.length)) {
        route = found
        sync = cx
        if (!found.length) break
      }
      if (cx.solid) break
    }
    if (!route) return null
    this.sync(sync!)
    for (let i = 0; i < route.length; i++)
      marks = this.enterInner(route[i], null, marks, false)
    return marks
  }

  // Try to insert the given node, adjusting the context when needed.
  insertNode(node: Node, marks: readonly Mark[]) {
    if (node.isInline && this.needsBlock && !this.top.type) {
      let block = this.textblockFromContext()
      if (block) marks = this.enterInner(block, null, marks)
    }
    let innerMarks = this.findPlace(node, marks)
    if (innerMarks) {
      this.closeExtra()
      let top = this.top
      if (top.match) top.match = top.match.matchType(node.type)
      let nodeMarks = Mark.none
      for (let m of innerMarks.concat(node.marks))
        if (top.type ? top.type.allowsMarkType(m.type) : markMayApply(m.type, node.type))
          nodeMarks = m.addToSet(nodeMarks)
      top.content.push(node.mark(nodeMarks))
      return true
    }
    return false
  }

  // Try to start a node of the given type, adjusting the context when
  // necessary.
  enter(type: NodeType, attrs: Attrs | null, marks: readonly Mark[], preserveWS?: boolean | "full") {
    let innerMarks = this.findPlace(type.create(attrs), marks)
    if (innerMarks) innerMarks = this.enterInner(type, attrs, marks, true, preserveWS)
    return innerMarks
  }

  // Open a node of the given type
  enterInner(type: NodeType, attrs: Attrs | null, marks: readonly Mark[],
             solid: boolean = false, preserveWS?: boolean | "full") {
    this.closeExtra()
    let top = this.top
    top.match = top.match && top.match.matchType(type)
    let options = wsOptionsFor(type, preserveWS, top.options)
    if ((top.options & OPT_OPEN_LEFT) && top.content.length == 0) options |= OPT_OPEN_LEFT
    let applyMarks = Mark.none
    marks = marks.filter(m => {
      if (top.type ? top.type.allowsMarkType(m.type) : markMayApply(m.type, type)) {
        applyMarks = m.addToSet(applyMarks)
        return false
      }
      return true
    })
    this.nodes.push(new NodeContext(type, attrs, applyMarks, solid, null, options))
    this.open++
    return marks
  }

  // Make sure all nodes above this.open are finished and added to
  // their parents
  closeExtra(openEnd = false) {
    let i = this.nodes.length - 1
    if (i > this.open) {
      for (; i > this.open; i--) this.nodes[i - 1].content.push(this.nodes[i].finish(openEnd) as Node)
      this.nodes.length = this.open + 1
    }
  }

  finish() {
    this.open = 0
    this.closeExtra(this.isOpen)
    return this.nodes[0].finish(this.isOpen || this.options.topOpen)
  }

  sync(to: NodeContext) {
    for (let i = this.open; i >= 0; i--) if (this.nodes[i] == to) {
      this.open = i
      return true
    }
    return false
  }

  get currentPos() {
    this.closeExtra()
    let pos = 0
    for (let i = this.open; i >= 0; i--) {
      let content = this.nodes[i].content
      for (let j = content.length - 1; j >= 0; j--)
        pos += content[j].nodeSize
      if (i) pos++
    }
    return pos
  }

  findAtPoint(parent: DOMNode, offset: number) {
    if (this.find) for (let i = 0; i < this.find.length; i++) {
      if (this.find[i].node == parent && this.find[i].offset == offset)
        this.find[i].pos = this.currentPos
    }
  }

  findInside(parent: DOMNode) {
    if (this.find) for (let i = 0; i < this.find.length; i++) {
      if (this.find[i].pos == null && parent.nodeType == 1 && parent.contains(this.find[i].node))
        this.find[i].pos = this.currentPos
    }
  }

  findAround(parent: DOMNode, content: DOMNode, before: boolean) {
    if (parent != content && this.find) for (let i = 0; i < this.find.length; i++) {
      if (this.find[i].pos == null && parent.nodeType == 1 && parent.contains(this.find[i].node)) {
        let pos = content.compareDocumentPosition(this.find[i].node)
        if (pos & (before ? 2 : 4))
          this.find[i].pos = this.currentPos
      }
    }
  }

  findInText(textNode: Text) {
    if (this.find) for (let i = 0; i < this.find.length; i++) {
      if (this.find[i].node == textNode)
        this.find[i].pos = this.currentPos - (textNode.nodeValue!.length - this.find[i].offset)
    }
  }

  // Determines whether the given context string matches this context.
  matchesContext(context: string) {
    if (context.indexOf("|") > -1)
      return context.split(/\s*\|\s*/).some(this.matchesContext, this)

    let parts = context.split("/")
    let option = this.options.context
    let useRoot = !this.isOpen && (!option || option.parent.type == this.nodes[0].type)
    let minDepth = -(option ? option.depth + 1 : 0) + (useRoot ? 0 : 1)
    let match = (i: number, depth: number) => {
      for (; i >= 0; i--) {
        let part = parts[i]
        if (part == "") {
          if (i == parts.length - 1 || i == 0) continue
          for (; depth >= minDepth; depth--)
            if (match(i - 1, depth)) return true
          return false
        } else {
          let next = depth > 0 || (depth == 0 && useRoot) ? this.nodes[depth].type
              : option && depth >= minDepth ? option.node(depth - minDepth).type
              : null
          if (!next || (next.name != part && next.groups.indexOf(part) == -1))
            return false
          depth--
        }
      }
      return true
    }
    return match(parts.length - 1, this.open)
  }

  textblockFromContext() {
    let $context = this.options.context
    if ($context) for (let d = $context.depth; d >= 0; d--) {
      let deflt = $context.node(d).contentMatchAt($context.indexAfter(d)).defaultType
      if (deflt && deflt.isTextblock && deflt.defaultAttrs) return deflt
    }
    for (let name in this.parser.schema.nodes) {
      let type = this.parser.schema.nodes[name]
      if (type.isTextblock && type.defaultAttrs) return type
    }
  }
}

// Kludge to work around directly nested list nodes produced by some
// tools and allowed by browsers to mean that the nested list is
// actually part of the list item above it.
function normalizeList(dom: DOMNode) {
  for (let child = dom.firstChild, prevItem: ChildNode | null = null; child; child = child.nextSibling) {
    let name = child.nodeType == 1 ? child.nodeName.toLowerCase() : null
    if (name && listTags.hasOwnProperty(name) && prevItem) {
      prevItem.appendChild(child)
      child = prevItem
    } else if (name == "li") {
      prevItem = child
    } else if (name) {
      prevItem = null
    }
  }
}

// Apply a CSS selector.
function matches(dom: any, selector: string): boolean {
  return (dom.matches || dom.msMatchesSelector || dom.webkitMatchesSelector || dom.mozMatchesSelector).call(dom, selector)
}

function copy(obj: {[prop: string]: any}) {
  let copy: {[prop: string]: any} = {}
  for (let prop in obj) copy[prop] = obj[prop]
  return copy
}

// Used when finding a mark at the top level of a fragment parse.
// Checks whether it would be reasonable to apply a given mark type to
// a given node, by looking at the way the mark occurs in the schema.
function markMayApply(markType: MarkType, nodeType: NodeType) {
  let nodes = nodeType.schema.nodes
  for (let name in nodes) {
    let parent = nodes[name]
    if (!parent.allowsMarkType(markType)) continue
    let seen: ContentMatch[] = [], scan = (match: ContentMatch) => {
      seen.push(match)
      for (let i = 0; i < match.edgeCount; i++) {
        let {type, next} = match.edge(i)
        if (type == nodeType) return true
        if (seen.indexOf(next) < 0 && scan(next)) return true
      }
    }
    if (scan(parent.contentMatch)) return true
  }
}
