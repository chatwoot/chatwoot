import {Plugin} from "prosemirror-state"
import {dropPoint} from "prosemirror-transform"

// :: (options: ?Object) → Plugin
// Create a plugin that, when added to a ProseMirror instance,
// causes a decoration to show up at the drop position when something
// is dragged over the editor.
//
//   options::- These options are supported:
//
//     color:: ?string
//     The color of the cursor. Defaults to `black`.
//
//     width:: ?number
//     The precise width of the cursor in pixels. Defaults to 1.
//
//     class:: ?string
//     A CSS class name to add to the cursor element.
export function dropCursor(options = {}) {
  return new Plugin({
    view(editorView) { return new DropCursorView(editorView, options) }
  })
}

class DropCursorView {
  constructor(editorView, options) {
    this.editorView = editorView
    this.width = options.width || 1
    this.color = options.color || "black"
    this.class = options.class
    this.cursorPos = null
    this.element = null
    this.timeout = null

    this.handlers = ["dragover", "dragend", "drop", "dragleave"].map(name => {
      let handler = e => this[name](e)
      editorView.dom.addEventListener(name, handler)
      return {name, handler}
    })
  }

  destroy() {
    this.handlers.forEach(({name, handler}) => this.editorView.dom.removeEventListener(name, handler))
  }

  update(editorView, prevState) {
    if (this.cursorPos != null && prevState.doc != editorView.state.doc) this.updateOverlay()
  }

  setCursor(pos) {
    if (pos == this.cursorPos) return
    this.cursorPos = pos
    if (pos == null) {
      this.element.parentNode.removeChild(this.element)
      this.element = null
    } else {
      this.updateOverlay()
    }
  }

  updateOverlay() {
    let $pos = this.editorView.state.doc.resolve(this.cursorPos), rect
    if (!$pos.parent.inlineContent) {
      let before = $pos.nodeBefore, after = $pos.nodeAfter
      if (before || after) {
        let nodeRect = this.editorView.nodeDOM(this.cursorPos - (before ?  before.nodeSize : 0)).getBoundingClientRect()
        let top = before ? nodeRect.bottom : nodeRect.top
        if (before && after)
          top = (top + this.editorView.nodeDOM(this.cursorPos).getBoundingClientRect().top) / 2
        rect = {left: nodeRect.left, right: nodeRect.right, top: top - this.width / 2, bottom: top + this.width / 2}
      }
    }
    if (!rect) {
      let coords = this.editorView.coordsAtPos(this.cursorPos)
      rect = {left: coords.left - this.width / 2, right: coords.left + this.width / 2, top: coords.top, bottom: coords.bottom}
    }

    let parent = this.editorView.dom.offsetParent
    if (!this.element) {
      this.element = parent.appendChild(document.createElement("div"))
      if (this.class) this.element.className = this.class
      this.element.style.cssText = "position: absolute; z-index: 50; pointer-events: none; background-color: " + this.color
    }
    let parentRect = !parent || parent == document.body && getComputedStyle(parent).position == "static"
        ? {left: -pageXOffset, top: -pageYOffset} : parent.getBoundingClientRect()
    this.element.style.left = (rect.left - parentRect.left) + "px"
    this.element.style.top = (rect.top - parentRect.top) + "px"
    this.element.style.width = (rect.right - rect.left) + "px"
    this.element.style.height = (rect.bottom - rect.top) + "px"
  }

  scheduleRemoval(timeout) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.setCursor(null), timeout)
  }

  dragover(event) {
    if (!this.editorView.editable) return
    let pos = this.editorView.posAtCoords({left: event.clientX, top: event.clientY})
    if (pos) {
      let target = pos.pos
      if (this.editorView.dragging && this.editorView.dragging.slice) {
        target = dropPoint(this.editorView.state.doc, target, this.editorView.dragging.slice)
        if (target == null) target = pos.pos
      }
      this.setCursor(target)
      this.scheduleRemoval(5000)
    }
  }

  dragend() {
    this.scheduleRemoval(20)
  }

  drop() {
    this.scheduleRemoval(20)
  }

  dragleave(event) {
    if (event.target == this.editorView.dom || !this.editorView.dom.contains(event.relatedTarget))
      this.setCursor(null)
  }
}
