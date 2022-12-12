import {DOMSerializer, Fragment, Mark} from "prosemirror-model"
import {TextSelection} from "prosemirror-state"

import {domIndex, isEquivalentPosition, nodeSize} from "./dom"
import browser from "./browser"

// NodeView:: interface
//
// By default, document nodes are rendered using the result of the
// [`toDOM`](#model.NodeSpec.toDOM) method of their spec, and managed
// entirely by the editor. For some use cases, such as embedded
// node-specific editing interfaces, you want more control over
// the behavior of a node's in-editor representation, and need to
// [define](#view.EditorProps.nodeViews) a custom node view.
//
// Mark views only support `dom` and `contentDOM`, and don't support
// any of the node view methods.
//
// Objects returned as node views must conform to this interface.
//
//   dom:: ?dom.Node
//   The outer DOM node that represents the document node. When not
//   given, the default strategy is used to create a DOM node.
//
//   contentDOM:: ?dom.Node
//   The DOM node that should hold the node's content. Only meaningful
//   if the node view also defines a `dom` property and if its node
//   type is not a leaf node type. When this is present, ProseMirror
//   will take care of rendering the node's children into it. When it
//   is not present, the node view itself is responsible for rendering
//   (or deciding not to render) its child nodes.
//
//   update:: ?(node: Node, decorations: [Decoration], innerDecorations: DecorationSource) → bool
//   When given, this will be called when the view is updating itself.
//   It will be given a node (possibly of a different type), an array
//   of active decorations around the node (which are automatically
//   drawn, and the node view may ignore if it isn't interested in
//   them), and a [decoration source](#view.DecorationSource) that
//   represents any decorations that apply to the content of the node
//   (which again may be ignored). It should return true if it was
//   able to update to that node, and false otherwise. If the node
//   view has a `contentDOM` property (or no `dom` property), updating
//   its child nodes will be handled by ProseMirror.
//
//   selectNode:: ?()
//   Can be used to override the way the node's selected status (as a
//   node selection) is displayed.
//
//   deselectNode:: ?()
//   When defining a `selectNode` method, you should also provide a
//   `deselectNode` method to remove the effect again.
//
//   setSelection:: ?(anchor: number, head: number, root: dom.Document)
//   This will be called to handle setting the selection inside the
//   node. The `anchor` and `head` positions are relative to the start
//   of the node. By default, a DOM selection will be created between
//   the DOM positions corresponding to those positions, but if you
//   override it you can do something else.
//
//   stopEvent:: ?(event: dom.Event) → bool
//   Can be used to prevent the editor view from trying to handle some
//   or all DOM events that bubble up from the node view. Events for
//   which this returns true are not handled by the editor.
//
//   ignoreMutation:: ?(dom.MutationRecord) → bool
//   Called when a DOM
//   [mutation](https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver)
//   or a selection change happens within the view. When the change is
//   a selection change, the record will have a `type` property of
//   `"selection"` (which doesn't occur for native mutation records).
//   Return false if the editor should re-read the selection or
//   re-parse the range around the mutation, true if it can safely be
//   ignored.
//
//   destroy:: ?()
//   Called when the node view is removed from the editor or the whole
//   editor is destroyed. (Not available for marks.)

// View descriptions are data structures that describe the DOM that is
// used to represent the editor's content. They are used for:
//
// - Incremental redrawing when the document changes
//
// - Figuring out what part of the document a given DOM position
//   corresponds to
//
// - Wiring in custom implementations of the editing interface for a
//   given node
//
// They form a doubly-linked mutable tree, starting at `view.docView`.

const NOT_DIRTY = 0, CHILD_DIRTY = 1, CONTENT_DIRTY = 2, NODE_DIRTY = 3

// Superclass for the various kinds of descriptions. Defines their
// basic structure and shared methods.
class ViewDesc {
  // : (?ViewDesc, [ViewDesc], dom.Node, ?dom.Node)
  constructor(parent, children, dom, contentDOM) {
    this.parent = parent
    this.children = children
    this.dom = dom
    // An expando property on the DOM node provides a link back to its
    // description.
    dom.pmViewDesc = this
    // This is the node that holds the child views. It may be null for
    // descs that don't have children.
    this.contentDOM = contentDOM
    this.dirty = NOT_DIRTY
  }

  // Used to check whether a given description corresponds to a
  // widget/mark/node.
  matchesWidget() { return false }
  matchesMark() { return false }
  matchesNode() { return false }
  matchesHack() { return false }

  get beforePosition() { return false }

  // : () → ?ParseRule
  // When parsing in-editor content (in domchange.js), we allow
  // descriptions to determine the parse rules that should be used to
  // parse them.
  parseRule() { return null }

  // : (dom.Event) → bool
  // Used by the editor's event handler to ignore events that come
  // from certain descs.
  stopEvent() { return false }

  // The size of the content represented by this desc.
  get size() {
    let size = 0
    for (let i = 0; i < this.children.length; i++) size += this.children[i].size
    return size
  }

  // For block nodes, this represents the space taken up by their
  // start/end tokens.
  get border() { return 0 }

  destroy() {
    this.parent = null
    if (this.dom.pmViewDesc == this) this.dom.pmViewDesc = null
    for (let i = 0; i < this.children.length; i++)
      this.children[i].destroy()
  }

  posBeforeChild(child) {
    for (let i = 0, pos = this.posAtStart; i < this.children.length; i++) {
      let cur = this.children[i]
      if (cur == child) return pos
      pos += cur.size
    }
  }

  get posBefore() {
    return this.parent.posBeforeChild(this)
  }

  get posAtStart() {
    return this.parent ? this.parent.posBeforeChild(this) + this.border : 0
  }

  get posAfter() {
    return this.posBefore + this.size
  }

  get posAtEnd() {
    return this.posAtStart + this.size - 2 * this.border
  }

  // : (dom.Node, number, ?number) → number
  localPosFromDOM(dom, offset, bias) {
    // If the DOM position is in the content, use the child desc after
    // it to figure out a position.
    if (this.contentDOM && this.contentDOM.contains(dom.nodeType == 1 ? dom : dom.parentNode)) {
      if (bias < 0) {
        let domBefore, desc
        if (dom == this.contentDOM) {
          domBefore = dom.childNodes[offset - 1]
        } else {
          while (dom.parentNode != this.contentDOM) dom = dom.parentNode
          domBefore = dom.previousSibling
        }
        while (domBefore && !((desc = domBefore.pmViewDesc) && desc.parent == this)) domBefore = domBefore.previousSibling
        return domBefore ? this.posBeforeChild(desc) + desc.size : this.posAtStart
      } else {
        let domAfter, desc
        if (dom == this.contentDOM) {
          domAfter = dom.childNodes[offset]
        } else {
          while (dom.parentNode != this.contentDOM) dom = dom.parentNode
          domAfter = dom.nextSibling
        }
        while (domAfter && !((desc = domAfter.pmViewDesc) && desc.parent == this)) domAfter = domAfter.nextSibling
        return domAfter ? this.posBeforeChild(desc) : this.posAtEnd
      }
    }
    // Otherwise, use various heuristics, falling back on the bias
    // parameter, to determine whether to return the position at the
    // start or at the end of this view desc.
    let atEnd
    if (dom == this.dom && this.contentDOM) {
      atEnd = offset > domIndex(this.contentDOM)
    } else if (this.contentDOM && this.contentDOM != this.dom && this.dom.contains(this.contentDOM)) {
      atEnd = dom.compareDocumentPosition(this.contentDOM) & 2
    } else if (this.dom.firstChild) {
      if (offset == 0) for (let search = dom;; search = search.parentNode) {
        if (search == this.dom) { atEnd = false; break }
        if (search.parentNode.firstChild != search) break
      }
      if (atEnd == null && offset == dom.childNodes.length) for (let search = dom;; search = search.parentNode) {
        if (search == this.dom) { atEnd = true; break }
        if (search.parentNode.lastChild != search) break
      }
    }
    return (atEnd == null ? bias > 0 : atEnd) ? this.posAtEnd : this.posAtStart
  }

  // Scan up the dom finding the first desc that is a descendant of
  // this one.
  nearestDesc(dom, onlyNodes) {
    for (let first = true, cur = dom; cur; cur = cur.parentNode) {
      let desc = this.getDesc(cur)
      if (desc && (!onlyNodes || desc.node)) {
        // If dom is outside of this desc's nodeDOM, don't count it.
        if (first && desc.nodeDOM &&
            !(desc.nodeDOM.nodeType == 1 ? desc.nodeDOM.contains(dom.nodeType == 1 ? dom : dom.parentNode) : desc.nodeDOM == dom))
          first = false
        else
          return desc
      }
    }
  }

  getDesc(dom) {
    let desc = dom.pmViewDesc
    for (let cur = desc; cur; cur = cur.parent) if (cur == this) return desc
  }

  posFromDOM(dom, offset, bias) {
    for (let scan = dom; scan; scan = scan.parentNode) {
      let desc = this.getDesc(scan)
      if (desc) return desc.localPosFromDOM(dom, offset, bias)
    }
    return -1
  }

  // : (number) → ?NodeViewDesc
  // Find the desc for the node after the given pos, if any. (When a
  // parent node overrode rendering, there might not be one.)
  descAt(pos) {
    for (let i = 0, offset = 0; i < this.children.length; i++) {
      let child = this.children[i], end = offset + child.size
      if (offset == pos && end != offset) {
        while (!child.border && child.children.length) child = child.children[0]
        return child
      }
      if (pos < end) return child.descAt(pos - offset - child.border)
      offset = end
    }
  }

  // : (number, number) → {node: dom.Node, offset: number}
  domFromPos(pos, side) {
    if (!this.contentDOM) return {node: this.dom, offset: 0}
    for (let offset = 0, i = 0, first = true;; i++, first = false) {
      // Skip removed or always-before children
      while (i < this.children.length && (this.children[i].beforePosition ||
                                          this.children[i].dom.parentNode != this.contentDOM))
        offset += this.children[i++].size
      let child = i == this.children.length ? null : this.children[i]
      if (offset == pos && (side == 0 || !child || !child.size || child.border || (side < 0 && first)) ||
          child && child.domAtom && pos < offset + child.size) return {
        node: this.contentDOM,
        offset: child ? domIndex(child.dom) : this.contentDOM.childNodes.length
      }
      if (!child) throw new Error("Invalid position " + pos)
      let end = offset + child.size
      if (!child.domAtom && (side < 0 && !child.border ? end >= pos : end > pos) &&
          (end > pos || i + 1 >= this.children.length || !this.children[i + 1].beforePosition))
        return child.domFromPos(pos - offset - child.border, side)
      offset = end
    }
  }

  // Used to find a DOM range in a single parent for a given changed
  // range.
  parseRange(from, to, base = 0) {
    if (this.children.length == 0)
      return {node: this.contentDOM, from, to, fromOffset: 0, toOffset: this.contentDOM.childNodes.length}

    let fromOffset = -1, toOffset = -1
    for (let offset = base, i = 0;; i++) {
      let child = this.children[i], end = offset + child.size
      if (fromOffset == -1 && from <= end) {
        let childBase = offset + child.border
        // FIXME maybe descend mark views to parse a narrower range?
        if (from >= childBase && to <= end - child.border && child.node &&
            child.contentDOM && this.contentDOM.contains(child.contentDOM))
          return child.parseRange(from, to, childBase)

        from = offset
        for (let j = i; j > 0; j--) {
          let prev = this.children[j - 1]
          if (prev.size && prev.dom.parentNode == this.contentDOM && !prev.emptyChildAt(1)) {
            fromOffset = domIndex(prev.dom) + 1
            break
          }
          from -= prev.size
        }
        if (fromOffset == -1) fromOffset = 0
      }
      if (fromOffset > -1 && (end > to || i == this.children.length - 1)) {
        to = end
        for (let j = i + 1; j < this.children.length; j++) {
          let next = this.children[j]
          if (next.size && next.dom.parentNode == this.contentDOM && !next.emptyChildAt(-1)) {
            toOffset = domIndex(next.dom)
            break
          }
          to += next.size
        }
        if (toOffset == -1) toOffset = this.contentDOM.childNodes.length
        break
      }
      offset = end
    }
    return {node: this.contentDOM, from, to, fromOffset, toOffset}
  }

  emptyChildAt(side) {
    if (this.border || !this.contentDOM || !this.children.length) return false
    let child = this.children[side < 0 ? 0 : this.children.length - 1]
    return child.size == 0 || child.emptyChildAt(side)
  }

  // : (number) → dom.Node
  domAfterPos(pos) {
    let {node, offset} = this.domFromPos(pos, 0)
    if (node.nodeType != 1 || offset == node.childNodes.length)
      throw new RangeError("No node after pos " + pos)
    return node.childNodes[offset]
  }

  // : (number, number, dom.Document)
  // View descs are responsible for setting any selection that falls
  // entirely inside of them, so that custom implementations can do
  // custom things with the selection. Note that this falls apart when
  // a selection starts in such a node and ends in another, in which
  // case we just use whatever domFromPos produces as a best effort.
  setSelection(anchor, head, root, force) {
    // If the selection falls entirely in a child, give it to that child
    let from = Math.min(anchor, head), to = Math.max(anchor, head)
    for (let i = 0, offset = 0; i < this.children.length; i++) {
      let child = this.children[i], end = offset + child.size
      if (from > offset && to < end)
        return child.setSelection(anchor - offset - child.border, head - offset - child.border, root, force)
      offset = end
    }

    let anchorDOM = this.domFromPos(anchor, anchor ? -1 : 1)
    let headDOM = head == anchor ? anchorDOM : this.domFromPos(head, head ? -1 : 1)
    let domSel = root.getSelection()

    let brKludge = false
    // On Firefox, using Selection.collapse to put the cursor after a
    // BR node for some reason doesn't always work (#1073). On Safari,
    // the cursor sometimes inexplicable visually lags behind its
    // reported position in such situations (#1092).
    if ((browser.gecko || browser.safari) && anchor == head) {
      let {node, offset} = anchorDOM
      if (node.nodeType == 3) {
        brKludge = offset && node.nodeValue[offset - 1] == "\n"
        // Issue #1128
        if (brKludge && offset == node.nodeValue.length &&
            node.nextSibling && node.nextSibling.nodeName == "BR")
          anchorDOM = headDOM = {node: node.parentNode, offset: domIndex(node) + 1}
      } else {
        let prev = node.childNodes[offset - 1]
        brKludge = prev && (prev.nodeName == "BR" || prev.contentEditable == "false")
      }
    }

    if (!(force || brKludge && browser.safari) &&
        isEquivalentPosition(anchorDOM.node, anchorDOM.offset, domSel.anchorNode, domSel.anchorOffset) &&
        isEquivalentPosition(headDOM.node, headDOM.offset, domSel.focusNode, domSel.focusOffset))
      return

    // Selection.extend can be used to create an 'inverted' selection
    // (one where the focus is before the anchor), but not all
    // browsers support it yet.
    let domSelExtended = false
    if ((domSel.extend || anchor == head) && !brKludge) {
      domSel.collapse(anchorDOM.node, anchorDOM.offset)
      try {
        if (anchor != head) domSel.extend(headDOM.node, headDOM.offset)
        domSelExtended = true
      } catch (err) {
        // In some cases with Chrome the selection is empty after calling
        // collapse, even when it should be valid. This appears to be a bug, but
        // it is difficult to isolate. If this happens fallback to the old path
        // without using extend.
        if (!(err instanceof DOMException)) throw err
        // declare global: DOMException
      }
    }
    if (!domSelExtended) {
      if (anchor > head) { let tmp = anchorDOM; anchorDOM = headDOM; headDOM = tmp }
      let range = document.createRange()
      range.setEnd(headDOM.node, headDOM.offset)
      range.setStart(anchorDOM.node, anchorDOM.offset)
      domSel.removeAllRanges()
      domSel.addRange(range)
    }
  }

  // : (dom.MutationRecord) → bool
  ignoreMutation(mutation) {
    return !this.contentDOM && mutation.type != "selection"
  }

  get contentLost() {
    return this.contentDOM && this.contentDOM != this.dom && !this.dom.contains(this.contentDOM)
  }

  // Remove a subtree of the element tree that has been touched
  // by a DOM change, so that the next update will redraw it.
  markDirty(from, to) {
    for (let offset = 0, i = 0; i < this.children.length; i++) {
      let child = this.children[i], end = offset + child.size
      if (offset == end ? from <= end && to >= offset : from < end && to > offset) {
        let startInside = offset + child.border, endInside = end - child.border
        if (from >= startInside && to <= endInside) {
          this.dirty = from == offset || to == end ? CONTENT_DIRTY : CHILD_DIRTY
          if (from == startInside && to == endInside &&
              (child.contentLost || child.dom.parentNode != this.contentDOM)) child.dirty = NODE_DIRTY
          else child.markDirty(from - startInside, to - startInside)
          return
        } else {
          child.dirty = NODE_DIRTY
        }
      }
      offset = end
    }
    this.dirty = CONTENT_DIRTY
  }

  markParentsDirty() {
    let level = 1
    for (let node = this.parent; node; node = node.parent, level++) {
      let dirty = level == 1 ? CONTENT_DIRTY : CHILD_DIRTY
      if (node.dirty < dirty) node.dirty = dirty
    }
  }

  get domAtom() { return false }
}

// Reused array to avoid allocating fresh arrays for things that will
// stay empty anyway.
const nothing = []

// A widget desc represents a widget decoration, which is a DOM node
// drawn between the document nodes.
class WidgetViewDesc extends ViewDesc {
  // : (ViewDesc, Decoration)
  constructor(parent, widget, view, pos) {
    let self, dom = widget.type.toDOM
    if (typeof dom == "function") dom = dom(view, () => {
      if (!self) return pos
      if (self.parent) return self.parent.posBeforeChild(self)
    })
    if (!widget.type.spec.raw) {
      if (dom.nodeType != 1) {
        let wrap = document.createElement("span")
        wrap.appendChild(dom)
        dom = wrap
      }
      dom.contentEditable = false
      dom.classList.add("ProseMirror-widget")
    }
    super(parent, nothing, dom, null)
    this.widget = widget
    self = this
  }

  get beforePosition() {
    return this.widget.type.side < 0
  }

  matchesWidget(widget) {
    return this.dirty == NOT_DIRTY && widget.type.eq(this.widget.type)
  }

  parseRule() { return {ignore: true} }

  stopEvent(event) {
    let stop = this.widget.spec.stopEvent
    return stop ? stop(event) : false
  }

  ignoreMutation(mutation) {
    return mutation.type != "selection" || this.widget.spec.ignoreSelection
  }

  get domAtom() { return true }
}

class CompositionViewDesc extends ViewDesc {
  constructor(parent, dom, textDOM, text) {
    super(parent, nothing, dom, null)
    this.textDOM = textDOM
    this.text = text
  }

  get size() { return this.text.length }

  localPosFromDOM(dom, offset) {
    if (dom != this.textDOM) return this.posAtStart + (offset ? this.size : 0)
    return this.posAtStart + offset
  }

  domFromPos(pos) {
    return {node: this.textDOM, offset: pos}
  }

  ignoreMutation(mut) {
    return mut.type === 'characterData' && mut.target.nodeValue == mut.oldValue
   }
}

// A mark desc represents a mark. May have multiple children,
// depending on how the mark is split. Note that marks are drawn using
// a fixed nesting order, for simplicity and predictability, so in
// some cases they will be split more often than would appear
// necessary.
class MarkViewDesc extends ViewDesc {
  // : (ViewDesc, Mark, dom.Node)
  constructor(parent, mark, dom, contentDOM) {
    super(parent, [], dom, contentDOM)
    this.mark = mark
  }

  static create(parent, mark, inline, view) {
    let custom = view.nodeViews[mark.type.name]
    let spec = custom && custom(mark, view, inline)
    if (!spec || !spec.dom)
      spec = DOMSerializer.renderSpec(document, mark.type.spec.toDOM(mark, inline))
    return new MarkViewDesc(parent, mark, spec.dom, spec.contentDOM || spec.dom)
  }

  parseRule() { return {mark: this.mark.type.name, attrs: this.mark.attrs, contentElement: this.contentDOM} }

  matchesMark(mark) { return this.dirty != NODE_DIRTY && this.mark.eq(mark) }

  markDirty(from, to) {
    super.markDirty(from, to)
    // Move dirty info to nearest node view
    if (this.dirty != NOT_DIRTY) {
      let parent = this.parent
      while (!parent.node) parent = parent.parent
      if (parent.dirty < this.dirty) parent.dirty = this.dirty
      this.dirty = NOT_DIRTY
    }
  }

  slice(from, to, view) {
    let copy = MarkViewDesc.create(this.parent, this.mark, true, view)
    let nodes = this.children, size = this.size
    if (to < size) nodes = replaceNodes(nodes, to, size, view)
    if (from > 0) nodes = replaceNodes(nodes, 0, from, view)
    for (let i = 0; i < nodes.length; i++) nodes[i].parent = copy
    copy.children = nodes
    return copy
  }
}

// Node view descs are the main, most common type of view desc, and
// correspond to an actual node in the document. Unlike mark descs,
// they populate their child array themselves.
class NodeViewDesc extends ViewDesc {
  // : (?ViewDesc, Node, [Decoration], DecorationSource, dom.Node, ?dom.Node, EditorView)
  constructor(parent, node, outerDeco, innerDeco, dom, contentDOM, nodeDOM, view, pos) {
    super(parent, node.isLeaf ? nothing : [], dom, contentDOM)
    this.nodeDOM = nodeDOM
    this.node = node
    this.outerDeco = outerDeco
    this.innerDeco = innerDeco
    if (contentDOM) this.updateChildren(view, pos)
  }

  // By default, a node is rendered using the `toDOM` method from the
  // node type spec. But client code can use the `nodeViews` spec to
  // supply a custom node view, which can influence various aspects of
  // the way the node works.
  //
  // (Using subclassing for this was intentionally decided against,
  // since it'd require exposing a whole slew of finnicky
  // implementation details to the user code that they probably will
  // never need.)
  static create(parent, node, outerDeco, innerDeco, view, pos) {
    let custom = view.nodeViews[node.type.name], descObj
    let spec = custom && custom(node, view, () => {
      // (This is a function that allows the custom view to find its
      // own position)
      if (!descObj) return pos
      if (descObj.parent) return descObj.parent.posBeforeChild(descObj)
    }, outerDeco, innerDeco)

    let dom = spec && spec.dom, contentDOM = spec && spec.contentDOM
    if (node.isText) {
      if (!dom) dom = document.createTextNode(node.text)
      else if (dom.nodeType != 3) throw new RangeError("Text must be rendered as a DOM text node")
    } else if (!dom) {
      ;({dom, contentDOM} = DOMSerializer.renderSpec(document, node.type.spec.toDOM(node)))
    }
    if (!contentDOM && !node.isText && dom.nodeName != "BR") { // Chrome gets confused by <br contenteditable=false>
      if (!dom.hasAttribute("contenteditable")) dom.contentEditable = false
      if (node.type.spec.draggable) dom.draggable = true
    }

    let nodeDOM = dom
    dom = applyOuterDeco(dom, outerDeco, node)

    if (spec)
      return descObj = new CustomNodeViewDesc(parent, node, outerDeco, innerDeco, dom, contentDOM, nodeDOM,
                                              spec, view, pos + 1)
    else if (node.isText)
      return new TextViewDesc(parent, node, outerDeco, innerDeco, dom, nodeDOM, view)
    else
      return new NodeViewDesc(parent, node, outerDeco, innerDeco, dom, contentDOM, nodeDOM, view, pos + 1)
  }

  parseRule() {
    // Experimental kludge to allow opt-in re-parsing of nodes
    if (this.node.type.spec.reparseInView) return null
    // FIXME the assumption that this can always return the current
    // attrs means that if the user somehow manages to change the
    // attrs in the dom, that won't be picked up. Not entirely sure
    // whether this is a problem
    let rule = {node: this.node.type.name, attrs: this.node.attrs}
    if (this.node.type.spec.code) rule.preserveWhitespace = "full"
    if (this.contentDOM && !this.contentLost) rule.contentElement = this.contentDOM
    else rule.getContent = () => this.contentDOM ? Fragment.empty : this.node.content
    return rule
  }

  matchesNode(node, outerDeco, innerDeco) {
    return this.dirty == NOT_DIRTY && node.eq(this.node) &&
      sameOuterDeco(outerDeco, this.outerDeco) && innerDeco.eq(this.innerDeco)
  }

  get size() { return this.node.nodeSize }

  get border() { return this.node.isLeaf ? 0 : 1 }

  // Syncs `this.children` to match `this.node.content` and the local
  // decorations, possibly introducing nesting for marks. Then, in a
  // separate step, syncs the DOM inside `this.contentDOM` to
  // `this.children`.
  updateChildren(view, pos) {
    let inline = this.node.inlineContent, off = pos
    let composition = inline && view.composing && this.localCompositionNode(view, pos)
    let updater = new ViewTreeUpdater(this, composition && composition.node)
    iterDeco(this.node, this.innerDeco, (widget, i, insideNode) => {
      if (widget.spec.marks)
        updater.syncToMarks(widget.spec.marks, inline, view)
      else if (widget.type.side >= 0 && !insideNode)
        updater.syncToMarks(i == this.node.childCount ? Mark.none : this.node.child(i).marks, inline, view)
      // If the next node is a desc matching this widget, reuse it,
      // otherwise insert the widget as a new view desc.
      updater.placeWidget(widget, view, off)
    }, (child, outerDeco, innerDeco, i) => {
      // Make sure the wrapping mark descs match the node's marks.
      updater.syncToMarks(child.marks, inline, view)
      // Either find an existing desc that exactly matches this node,
      // and drop the descs before it.
      updater.findNodeMatch(child, outerDeco, innerDeco, i) ||
        // Or try updating the next desc to reflect this node.
        updater.updateNextNode(child, outerDeco, innerDeco, view, i) ||
        // Or just add it as a new desc.
        updater.addNode(child, outerDeco, innerDeco, view, off)
      off += child.nodeSize
    })
    // Drop all remaining descs after the current position.
    updater.syncToMarks(nothing, inline, view)
    if (this.node.isTextblock) updater.addTextblockHacks()
    updater.destroyRest()

    // Sync the DOM if anything changed
    if (updater.changed || this.dirty == CONTENT_DIRTY) {
      // May have to protect focused DOM from being changed if a composition is active
      if (composition) this.protectLocalComposition(view, composition)
      renderDescs(this.contentDOM, this.children, view)
      if (browser.ios) iosHacks(this.dom)
    }
  }

  localCompositionNode(view, pos) {
    // Only do something if both the selection and a focused text node
    // are inside of this node, and the node isn't already part of a
    // view that's a child of this view
    let {from, to} = view.state.selection
    if (!(view.state.selection instanceof TextSelection) || from < pos || to > pos + this.node.content.size) return
    let sel = view.root.getSelection()
    let textNode = nearbyTextNode(sel.focusNode, sel.focusOffset)
    if (!textNode || !this.dom.contains(textNode.parentNode)) return

    // Find the text in the focused node in the node, stop if it's not
    // there (may have been modified through other means, in which
    // case it should overwritten)
    let text = textNode.nodeValue
    let textPos = findTextInFragment(this.node.content, text, from - pos, to - pos)

    return textPos < 0 ? null : {node: textNode, pos: textPos, text}
  }

  protectLocalComposition(view, {node, pos, text}) {
    // The node is already part of a local view desc, leave it there
    if (this.getDesc(node)) return

    // Create a composition view for the orphaned nodes
    let topNode = node
    for (;; topNode = topNode.parentNode) {
      if (topNode.parentNode == this.contentDOM) break
      while (topNode.previousSibling) topNode.parentNode.removeChild(topNode.previousSibling)
      while (topNode.nextSibling) topNode.parentNode.removeChild(topNode.nextSibling)
      if (topNode.pmViewDesc) topNode.pmViewDesc = null
    }
    let desc = new CompositionViewDesc(this, topNode, node, text)
    view.compositionNodes.push(desc)

    // Patch up this.children to contain the composition view
    this.children = replaceNodes(this.children, pos, pos + text.length, view, desc)
  }

  // : (Node, [Decoration], DecorationSource, EditorView) → bool
  // If this desc be updated to match the given node decoration,
  // do so and return true.
  update(node, outerDeco, innerDeco, view) {
    if (this.dirty == NODE_DIRTY ||
        !node.sameMarkup(this.node)) return false
    this.updateInner(node, outerDeco, innerDeco, view)
    return true
  }

  updateInner(node, outerDeco, innerDeco, view) {
    this.updateOuterDeco(outerDeco)
    this.node = node
    this.innerDeco = innerDeco
    if (this.contentDOM) this.updateChildren(view, this.posAtStart)
    this.dirty = NOT_DIRTY
  }

  updateOuterDeco(outerDeco) {
    if (sameOuterDeco(outerDeco, this.outerDeco)) return
    let needsWrap = this.nodeDOM.nodeType != 1
    let oldDOM = this.dom
    this.dom = patchOuterDeco(this.dom, this.nodeDOM,
                              computeOuterDeco(this.outerDeco, this.node, needsWrap),
                              computeOuterDeco(outerDeco, this.node, needsWrap))
    if (this.dom != oldDOM) {
      oldDOM.pmViewDesc = null
      this.dom.pmViewDesc = this
    }
    this.outerDeco = outerDeco
  }

  // Mark this node as being the selected node.
  selectNode() {
    this.nodeDOM.classList.add("ProseMirror-selectednode")
    if (this.contentDOM || !this.node.type.spec.draggable) this.dom.draggable = true
  }

  // Remove selected node marking from this node.
  deselectNode() {
    this.nodeDOM.classList.remove("ProseMirror-selectednode")
    if (this.contentDOM || !this.node.type.spec.draggable) this.dom.removeAttribute("draggable")
  }

  get domAtom() { return this.node.isAtom }
}

// Create a view desc for the top-level document node, to be exported
// and used by the view class.
export function docViewDesc(doc, outerDeco, innerDeco, dom, view) {
  applyOuterDeco(dom, outerDeco, doc)
  return new NodeViewDesc(null, doc, outerDeco, innerDeco, dom, dom, dom, view, 0)
}

class TextViewDesc extends NodeViewDesc {
  constructor(parent, node, outerDeco, innerDeco, dom, nodeDOM, view) {
    super(parent, node, outerDeco, innerDeco, dom, null, nodeDOM, view)
  }

  parseRule() {
    let skip = this.nodeDOM.parentNode
    while (skip && skip != this.dom && !skip.pmIsDeco) skip = skip.parentNode
    return {skip: skip || true}
  }

  update(node, outerDeco, _, view) {
    if (this.dirty == NODE_DIRTY || (this.dirty != NOT_DIRTY && !this.inParent()) ||
        !node.sameMarkup(this.node)) return false
    this.updateOuterDeco(outerDeco)
    if ((this.dirty != NOT_DIRTY || node.text != this.node.text) && node.text != this.nodeDOM.nodeValue) {
      this.nodeDOM.nodeValue = node.text
      if (view.trackWrites == this.nodeDOM) view.trackWrites = null
    }
    this.node = node
    this.dirty = NOT_DIRTY
    return true
  }

  inParent() {
    let parentDOM = this.parent.contentDOM
    for (let n = this.nodeDOM; n; n = n.parentNode) if (n == parentDOM) return true
    return false
  }

  domFromPos(pos) {
    return {node: this.nodeDOM, offset: pos}
  }

  localPosFromDOM(dom, offset, bias) {
    if (dom == this.nodeDOM) return this.posAtStart + Math.min(offset, this.node.text.length)
    return super.localPosFromDOM(dom, offset, bias)
  }

  ignoreMutation(mutation) {
    return mutation.type != "characterData" && mutation.type != "selection"
  }

  slice(from, to, view) {
    let node = this.node.cut(from, to), dom = document.createTextNode(node.text)
    return new TextViewDesc(this.parent, node, this.outerDeco, this.innerDeco, dom, dom, view)
  }

  get domAtom() { return false }
}

// A dummy desc used to tag trailing BR or span nodes created to work
// around contentEditable terribleness.
class BRHackViewDesc extends ViewDesc {
  parseRule() { return {ignore: true} }
  matchesHack() { return this.dirty == NOT_DIRTY }
  get domAtom() { return true }
}

// A separate subclass is used for customized node views, so that the
// extra checks only have to be made for nodes that are actually
// customized.
class CustomNodeViewDesc extends NodeViewDesc {
  // : (?ViewDesc, Node, [Decoration], DecorationSource, dom.Node, ?dom.Node, NodeView, EditorView)
  constructor(parent, node, outerDeco, innerDeco, dom, contentDOM, nodeDOM, spec, view, pos) {
    super(parent, node, outerDeco, innerDeco, dom, contentDOM, nodeDOM, view, pos)
    this.spec = spec
  }

  // A custom `update` method gets to decide whether the update goes
  // through. If it does, and there's a `contentDOM` node, our logic
  // updates the children.
  update(node, outerDeco, innerDeco, view) {
    if (this.dirty == NODE_DIRTY) return false
    if (this.spec.update) {
      let result = this.spec.update(node, outerDeco, innerDeco)
      if (result) this.updateInner(node, outerDeco, innerDeco, view)
      return result
    } else if (!this.contentDOM && !node.isLeaf) {
      return false
    } else {
      return super.update(node, outerDeco, innerDeco, view)
    }
  }

  selectNode() {
    this.spec.selectNode ? this.spec.selectNode() : super.selectNode()
  }

  deselectNode() {
    this.spec.deselectNode ? this.spec.deselectNode() : super.deselectNode()
  }

  setSelection(anchor, head, root, force) {
    this.spec.setSelection ? this.spec.setSelection(anchor, head, root)
      : super.setSelection(anchor, head, root, force)
  }

  destroy() {
    if (this.spec.destroy) this.spec.destroy()
    super.destroy()
  }

  stopEvent(event) {
    return this.spec.stopEvent ? this.spec.stopEvent(event) : false
  }

  ignoreMutation(mutation) {
    return this.spec.ignoreMutation ? this.spec.ignoreMutation(mutation) : super.ignoreMutation(mutation)
  }
}

// : (dom.Node, [ViewDesc])
// Sync the content of the given DOM node with the nodes associated
// with the given array of view descs, recursing into mark descs
// because this should sync the subtree for a whole node at a time.
function renderDescs(parentDOM, descs, view) {
  let dom = parentDOM.firstChild, written = false
  for (let i = 0; i < descs.length; i++) {
    let desc = descs[i], childDOM = desc.dom
    if (childDOM.parentNode == parentDOM) {
      while (childDOM != dom) { dom = rm(dom); written = true }
      dom = dom.nextSibling
    } else {
      written = true
      parentDOM.insertBefore(childDOM, dom)
    }
    if (desc instanceof MarkViewDesc) {
      let pos = dom ? dom.previousSibling : parentDOM.lastChild
      renderDescs(desc.contentDOM, desc.children, view)
      dom = pos ? pos.nextSibling : parentDOM.firstChild
    }
  }
  while (dom) { dom = rm(dom); written = true }
  if (written && view.trackWrites == parentDOM) view.trackWrites = null
}

function OuterDecoLevel(nodeName) {
  if (nodeName) this.nodeName = nodeName
}
OuterDecoLevel.prototype = Object.create(null)

const noDeco = [new OuterDecoLevel]

function computeOuterDeco(outerDeco, node, needsWrap) {
  if (outerDeco.length == 0) return noDeco

  let top = needsWrap ? noDeco[0] : new OuterDecoLevel, result = [top]

  for (let i = 0; i < outerDeco.length; i++) {
    let attrs = outerDeco[i].type.attrs
    if (!attrs) continue
    if (attrs.nodeName)
      result.push(top = new OuterDecoLevel(attrs.nodeName))

    for (let name in attrs) {
      let val = attrs[name]
      if (val == null) continue
      if (needsWrap && result.length == 1)
        result.push(top = new OuterDecoLevel(node.isInline ? "span" : "div"))
      if (name == "class") top.class = (top.class ? top.class + " " : "") + val
      else if (name == "style") top.style = (top.style ? top.style + ";" : "") + val
      else if (name != "nodeName") top[name] = val
    }
  }

  return result
}

function patchOuterDeco(outerDOM, nodeDOM, prevComputed, curComputed) {
  // Shortcut for trivial case
  if (prevComputed == noDeco && curComputed == noDeco) return nodeDOM

  let curDOM = nodeDOM
  for (let i = 0; i < curComputed.length; i++) {
    let deco = curComputed[i], prev = prevComputed[i]
    if (i) {
      let parent
      if (prev && prev.nodeName == deco.nodeName && curDOM != outerDOM &&
          (parent = curDOM.parentNode) && parent.tagName.toLowerCase() == deco.nodeName) {
        curDOM = parent
      } else {
        parent = document.createElement(deco.nodeName)
        parent.pmIsDeco = true
        parent.appendChild(curDOM)
        prev = noDeco[0]
        curDOM = parent
      }
    }
    patchAttributes(curDOM, prev || noDeco[0], deco)
  }
  return curDOM
}

function patchAttributes(dom, prev, cur) {
  for (let name in prev)
    if (name != "class" && name != "style" && name != "nodeName" && !(name in cur))
      dom.removeAttribute(name)
  for (let name in cur)
    if (name != "class" && name != "style" && name != "nodeName" && cur[name] != prev[name])
      dom.setAttribute(name, cur[name])
  if (prev.class != cur.class) {
    let prevList = prev.class ? prev.class.split(" ").filter(Boolean) : nothing
    let curList = cur.class ? cur.class.split(" ").filter(Boolean) : nothing
    for (let i = 0; i < prevList.length; i++) if (curList.indexOf(prevList[i]) == -1)
      dom.classList.remove(prevList[i])
    for (let i = 0; i < curList.length; i++) if (prevList.indexOf(curList[i]) == -1)
      dom.classList.add(curList[i])
  }
  if (prev.style != cur.style) {
    if (prev.style) {
      let prop = /\s*([\w\-\xa1-\uffff]+)\s*:(?:"(?:\\.|[^"])*"|'(?:\\.|[^'])*'|\(.*?\)|[^;])*/g, m
      while (m = prop.exec(prev.style))
        dom.style.removeProperty(m[1])
    }
    if (cur.style)
      dom.style.cssText += cur.style
  }
}

function applyOuterDeco(dom, deco, node) {
  return patchOuterDeco(dom, dom, noDeco, computeOuterDeco(deco, node, dom.nodeType != 1))
}

// : ([Decoration], [Decoration]) → bool
function sameOuterDeco(a, b) {
  if (a.length != b.length) return false
  for (let i = 0; i < a.length; i++) if (!a[i].type.eq(b[i].type)) return false
  return true
}

// Remove a DOM node and return its next sibling.
function rm(dom) {
  let next = dom.nextSibling
  dom.parentNode.removeChild(dom)
  return next
}

// Helper class for incrementally updating a tree of mark descs and
// the widget and node descs inside of them.
class ViewTreeUpdater {
  // : (NodeViewDesc)
  constructor(top, lockedNode) {
    this.top = top
    this.lock = lockedNode
    // Index into `this.top`'s child array, represents the current
    // update position.
    this.index = 0
    // When entering a mark, the current top and index are pushed
    // onto this.
    this.stack = []
    // Tracks whether anything was changed
    this.changed = false

    this.preMatch = preMatch(top.node.content, top.children)
  }

  // Destroy and remove the children between the given indices in
  // `this.top`.
  destroyBetween(start, end) {
    if (start == end) return
    for (let i = start; i < end; i++) this.top.children[i].destroy()
    this.top.children.splice(start, end - start)
    this.changed = true
  }

  // Destroy all remaining children in `this.top`.
  destroyRest() {
    this.destroyBetween(this.index, this.top.children.length)
  }

  // : ([Mark], EditorView)
  // Sync the current stack of mark descs with the given array of
  // marks, reusing existing mark descs when possible.
  syncToMarks(marks, inline, view) {
    let keep = 0, depth = this.stack.length >> 1
    let maxKeep = Math.min(depth, marks.length)
    while (keep < maxKeep &&
           (keep == depth - 1 ? this.top : this.stack[(keep + 1) << 1]).matchesMark(marks[keep]) && marks[keep].type.spec.spanning !== false)
      keep++

    while (keep < depth) {
      this.destroyRest()
      this.top.dirty = NOT_DIRTY
      this.index = this.stack.pop()
      this.top = this.stack.pop()
      depth--
    }
    while (depth < marks.length) {
      this.stack.push(this.top, this.index + 1)
      let found = -1
      for (let i = this.index; i < Math.min(this.index + 3, this.top.children.length); i++) {
        if (this.top.children[i].matchesMark(marks[depth])) { found = i; break }
      }
      if (found > -1) {
        if (found > this.index) {
          this.changed = true
          this.destroyBetween(this.index, found)
        }
        this.top = this.top.children[this.index]
      } else {
        let markDesc = MarkViewDesc.create(this.top, marks[depth], inline, view)
        this.top.children.splice(this.index, 0, markDesc)
        this.top = markDesc
        this.changed = true
      }
      this.index = 0
      depth++
    }
  }

  // : (Node, [Decoration], DecorationSource) → bool
  // Try to find a node desc matching the given data. Skip over it and
  // return true when successful.
  findNodeMatch(node, outerDeco, innerDeco, index) {
    let children = this.top.children, found = -1
    if (index >= this.preMatch.index) {
      for (let i = this.index; i < children.length; i++) if (children[i].matchesNode(node, outerDeco, innerDeco)) {
        found = i
        break
      }
    } else {
      for (let i = this.index, e = Math.min(children.length, i + 1); i < e; i++) {
        let child = children[i]
        if (child.matchesNode(node, outerDeco, innerDeco) && !this.preMatch.matched.has(child)) {
          found = i
          break
        }
      }
    }
    if (found < 0) return false
    this.destroyBetween(this.index, found)
    this.index++
    return true
  }

  // : (Node, [Decoration], DecorationSource, EditorView, Fragment, number) → bool
  // Try to update the next node, if any, to the given data. Checks
  // pre-matches to avoid overwriting nodes that could still be used.
  updateNextNode(node, outerDeco, innerDeco, view, index) {
    for (let i = this.index; i < this.top.children.length; i++) {
      let next = this.top.children[i]
      if (next instanceof NodeViewDesc) {
        let preMatch = this.preMatch.matched.get(next)
        if (preMatch != null && preMatch != index) return false
        let nextDOM = next.dom

        // Can't update if nextDOM is or contains this.lock, except if
        // it's a text node whose content already matches the new text
        // and whose decorations match the new ones.
        let locked = this.lock && (nextDOM == this.lock || nextDOM.nodeType == 1 && nextDOM.contains(this.lock.parentNode)) &&
            !(node.isText && next.node && next.node.isText && next.nodeDOM.nodeValue == node.text &&
              next.dirty != NODE_DIRTY && sameOuterDeco(outerDeco, next.outerDeco))
        if (!locked && next.update(node, outerDeco, innerDeco, view)) {
          this.destroyBetween(this.index, i)
          if (next.dom != nextDOM) this.changed = true
          this.index++
          return true
        }
        break
      }
    }
    return false
  }

  // : (Node, [Decoration], DecorationSource, EditorView)
  // Insert the node as a newly created node desc.
  addNode(node, outerDeco, innerDeco, view, pos) {
    this.top.children.splice(this.index++, 0, NodeViewDesc.create(this.top, node, outerDeco, innerDeco, view, pos))
    this.changed = true
  }

  placeWidget(widget, view, pos) {
    let next = this.index < this.top.children.length ? this.top.children[this.index] : null
    if (next && next.matchesWidget(widget) && (widget == next.widget || !next.widget.type.toDOM.parentNode)) {
      this.index++
    } else {
      let desc = new WidgetViewDesc(this.top, widget, view, pos)
      this.top.children.splice(this.index++, 0, desc)
      this.changed = true
    }
  }

  // Make sure a textblock looks and behaves correctly in
  // contentEditable.
  addTextblockHacks() {
    let lastChild = this.top.children[this.index - 1]
    while (lastChild instanceof MarkViewDesc) lastChild = lastChild.children[lastChild.children.length - 1]

    if (!lastChild || // Empty textblock
        !(lastChild instanceof TextViewDesc) ||
        /\n$/.test(lastChild.node.text)) {
      if (this.index < this.top.children.length && this.top.children[this.index].matchesHack()) {
        this.index++
      } else {
        let dom = document.createElement("br")
        this.top.children.splice(this.index++, 0, new BRHackViewDesc(this.top, nothing, dom, null))
        this.changed = true
      }
    }
  }
}

// : (Fragment, [ViewDesc]) → {index: number, matched: Map<ViewDesc, number>}
// Iterate from the end of the fragment and array of descs to find
// directly matching ones, in order to avoid overeagerly reusing those
// for other nodes. Returns the fragment index of the first node that
// is part of the sequence of matched nodes at the end of the
// fragment.
function preMatch(frag, descs) {
  let fI = frag.childCount, dI = descs.length, matched = new Map
  for (; fI > 0 && dI > 0; dI--) {
    let desc = descs[dI - 1], node = desc.node
    if (!node) continue
    if (node != frag.child(fI - 1)) break
    --fI
    matched.set(desc, fI)
  }
  return {index: fI, matched}
}

function compareSide(a, b) { return a.type.side - b.type.side }

// : (ViewDesc, DecorationSource, (Decoration, number), (Node, [Decoration], DecorationSource, number))
// This function abstracts iterating over the nodes and decorations in
// a fragment. Calls `onNode` for each node, with its local and child
// decorations. Splits text nodes when there is a decoration starting
// or ending inside of them. Calls `onWidget` for each widget.
function iterDeco(parent, deco, onWidget, onNode) {
  let locals = deco.locals(parent), offset = 0
  // Simple, cheap variant for when there are no local decorations
  if (locals.length == 0) {
    for (let i = 0; i < parent.childCount; i++) {
      let child = parent.child(i)
      onNode(child, locals, deco.forChild(offset, child), i)
      offset += child.nodeSize
    }
    return
  }

  let decoIndex = 0, active = [], restNode = null
  for (let parentIndex = 0;;) {
    if (decoIndex < locals.length && locals[decoIndex].to == offset) {
      let widget = locals[decoIndex++], widgets
      while (decoIndex < locals.length && locals[decoIndex].to == offset)
        (widgets || (widgets = [widget])).push(locals[decoIndex++])
      if (widgets) {
        widgets.sort(compareSide)
        for (let i = 0; i < widgets.length; i++) onWidget(widgets[i], parentIndex, !!restNode)
      } else {
        onWidget(widget, parentIndex, !!restNode)
      }
    }

    let child, index
    if (restNode) {
      index = -1
      child = restNode
      restNode = null
    } else if (parentIndex < parent.childCount) {
      index = parentIndex
      child = parent.child(parentIndex++)
    } else {
      break
    }

    for (let i = 0; i < active.length; i++) if (active[i].to <= offset) active.splice(i--, 1)
    while (decoIndex < locals.length && locals[decoIndex].from <= offset && locals[decoIndex].to > offset)
      active.push(locals[decoIndex++])

    let end = offset + child.nodeSize
    if (child.isText) {
      let cutAt = end
      if (decoIndex < locals.length && locals[decoIndex].from < cutAt) cutAt = locals[decoIndex].from
      for (let i = 0; i < active.length; i++) if (active[i].to < cutAt) cutAt = active[i].to
      if (cutAt < end) {
        restNode = child.cut(cutAt - offset)
        child = child.cut(0, cutAt - offset)
        end = cutAt
        index = -1
      }
    }

    let outerDeco = !active.length ? nothing
        : child.isInline && !child.isLeaf ? active.filter(d => !d.inline)
        : active.slice()
    onNode(child, outerDeco, deco.forChild(offset, child), index)
    offset = end
  }
}

// List markers in Mobile Safari will mysteriously disappear
// sometimes. This works around that.
function iosHacks(dom) {
  if (dom.nodeName == "UL" || dom.nodeName == "OL") {
    let oldCSS = dom.style.cssText
    dom.style.cssText = oldCSS + "; list-style: square !important"
    window.getComputedStyle(dom).listStyle
    dom.style.cssText = oldCSS
  }
}

function nearbyTextNode(node, offset) {
  for (;;) {
    if (node.nodeType == 3) return node
    if (node.nodeType == 1 && offset > 0) {
      if (node.childNodes.length > offset && node.childNodes[offset].nodeType == 3)
        return node.childNodes[offset]
      node = node.childNodes[offset - 1]
      offset = nodeSize(node)
    } else if (node.nodeType == 1 && offset < node.childNodes.length) {
      node = node.childNodes[offset]
      offset = 0
    } else {
      return null
    }
  }
}

// Find a piece of text in an inline fragment, overlapping from-to
function findTextInFragment(frag, text, from, to) {
  for (let i = 0, pos = 0; i < frag.childCount && pos <= to;) {
    let child = frag.child(i++), childStart = pos
    pos += child.nodeSize
    if (!child.isText) continue
    let str = child.text
    while (i < frag.childCount) {
      let next = frag.child(i++)
      pos += next.nodeSize
      if (!next.isText) break
      str += next.text
    }
    if (pos >= from) {
      let found = str.lastIndexOf(text, to - childStart)
      if (found >= 0 && found + text.length + childStart >= from)
        return childStart + found
    }
  }
  return -1
}

// Replace range from-to in an array of view descs with replacement
// (may be null to just delete). This goes very much against the grain
// of the rest of this code, which tends to create nodes with the
// right shape in one go, rather than messing with them after
// creation, but is necessary in the composition hack.
function replaceNodes(nodes, from, to, view, replacement) {
  let result = []
  for (let i = 0, off = 0; i < nodes.length; i++) {
    let child = nodes[i], start = off, end = off += child.size
    if (start >= to || end <= from) {
      result.push(child)
    } else {
      if (start < from) result.push(child.slice(0, from - start, view))
      if (replacement) {
        result.push(replacement)
        replacement = null
      }
      if (end > to) result.push(child.slice(to - start, child.size, view))
    }
  }
  return result
}
