import {Selection, NodeSelection, TextSelection} from "prosemirror-state"
import {dropPoint} from "prosemirror-transform"
import {Slice} from "prosemirror-model"

import browser from "./browser"
import {captureKeyDown} from "./capturekeys"
import {readDOMChange} from "./domchange"
import {parseFromClipboard, serializeForClipboard} from "./clipboard"
import {DOMObserver} from "./domobserver"
import {selectionBetween, selectionToDOM, selectionFromDOM} from "./selection"
import {keyEvent} from "./dom"

// A collection of DOM events that occur within the editor, and callback functions
// to invoke when the event fires.
const handlers = {}, editHandlers = {}

export function initInput(view) {
  view.shiftKey = false
  view.mouseDown = null
  view.lastKeyCode = null
  view.lastKeyCodeTime = 0
  view.lastClick = {time: 0, x: 0, y: 0, type: ""}
  view.lastSelectionOrigin = null
  view.lastSelectionTime = 0

  view.lastIOSEnter = 0
  view.lastIOSEnterFallbackTimeout = null
  view.lastAndroidDelete = 0

  view.composing = false
  view.composingTimeout = null
  view.compositionNodes = []
  view.compositionEndedAt = -2e8

  view.domObserver = new DOMObserver(view, (from, to, typeOver, added) => readDOMChange(view, from, to, typeOver, added))
  view.domObserver.start()
  // Used by hacks like the beforeinput handler to check whether anything happened in the DOM
  view.domChangeCount = 0

  view.eventHandlers = Object.create(null)
  for (let event in handlers) {
    let handler = handlers[event]
    view.dom.addEventListener(event, view.eventHandlers[event] = event => {
      if (eventBelongsToView(view, event) && !runCustomHandler(view, event) &&
          (view.editable || !(event.type in editHandlers)))
        handler(view, event)
    })
  }
  // On Safari, for reasons beyond my understanding, adding an input
  // event handler makes an issue where the composition vanishes when
  // you press enter go away.
  if (browser.safari) view.dom.addEventListener("input", () => null)

  ensureListeners(view)
}

function setSelectionOrigin(view, origin) {
  view.lastSelectionOrigin = origin
  view.lastSelectionTime = Date.now()
}

export function destroyInput(view) {
  view.domObserver.stop()
  for (let type in view.eventHandlers)
    view.dom.removeEventListener(type, view.eventHandlers[type])
  clearTimeout(view.composingTimeout)
  clearTimeout(view.lastIOSEnterFallbackTimeout)
}

export function ensureListeners(view) {
  view.someProp("handleDOMEvents", currentHandlers => {
    for (let type in currentHandlers) if (!view.eventHandlers[type])
      view.dom.addEventListener(type, view.eventHandlers[type] = event => runCustomHandler(view, event))
  })
}

function runCustomHandler(view, event) {
  return view.someProp("handleDOMEvents", handlers => {
    let handler = handlers[event.type]
    return handler ? handler(view, event) || event.defaultPrevented : false
  })
}

function eventBelongsToView(view, event) {
  if (!event.bubbles) return true
  if (event.defaultPrevented) return false
  for (let node = event.target; node != view.dom; node = node.parentNode)
    if (!node || node.nodeType == 11 ||
        (node.pmViewDesc && node.pmViewDesc.stopEvent(event)))
      return false
  return true
}

export function dispatchEvent(view, event) {
  if (!runCustomHandler(view, event) && handlers[event.type] &&
      (view.editable || !(event.type in editHandlers)))
    handlers[event.type](view, event)
}

editHandlers.keydown = (view, event) => {
  view.shiftKey = event.keyCode == 16 || event.shiftKey
  if (inOrNearComposition(view, event)) return
  view.domObserver.forceFlush()
  view.lastKeyCode = event.keyCode
  view.lastKeyCodeTime = Date.now()
  // On iOS, if we preventDefault enter key presses, the virtual
  // keyboard gets confused. So the hack here is to set a flag that
  // makes the DOM change code recognize that what just happens should
  // be replaced by whatever the Enter key handlers do.
  if (browser.ios && event.keyCode == 13 && !event.ctrlKey && !event.altKey && !event.metaKey) {
    let now = Date.now()
    view.lastIOSEnter = now
    view.lastIOSEnterFallbackTimeout = setTimeout(() => {
      if (view.lastIOSEnter == now) {
        view.someProp("handleKeyDown", f => f(view, keyEvent(13, "Enter")))
        view.lastIOSEnter = 0
      }
    }, 200)
  } else if (view.someProp("handleKeyDown", f => f(view, event)) || captureKeyDown(view, event)) {
    event.preventDefault()
  } else {
    setSelectionOrigin(view, "key")
  }
}

editHandlers.keyup = (view, e) => {
  if (e.keyCode == 16) view.shiftKey = false
}

editHandlers.keypress = (view, event) => {
  if (inOrNearComposition(view, event) || !event.charCode ||
      event.ctrlKey && !event.altKey || browser.mac && event.metaKey) return

  if (view.someProp("handleKeyPress", f => f(view, event))) {
    event.preventDefault()
    return
  }

  let sel = view.state.selection
  if (!(sel instanceof TextSelection) || !sel.$from.sameParent(sel.$to)) {
    let text = String.fromCharCode(event.charCode)
    if (!view.someProp("handleTextInput", f => f(view, sel.$from.pos, sel.$to.pos, text)))
      view.dispatch(view.state.tr.insertText(text).scrollIntoView())
    event.preventDefault()
  }
}

function eventCoords(event) { return {left: event.clientX, top: event.clientY} }

function isNear(event, click) {
  let dx = click.x - event.clientX, dy = click.y - event.clientY
  return dx * dx + dy * dy < 100
}

function runHandlerOnContext(view, propName, pos, inside, event) {
  if (inside == -1) return false
  let $pos = view.state.doc.resolve(inside)
  for (let i = $pos.depth + 1; i > 0; i--) {
    if (view.someProp(propName, f => i > $pos.depth ? f(view, pos, $pos.nodeAfter, $pos.before(i), event, true)
                                                    : f(view, pos, $pos.node(i), $pos.before(i), event, false)))
      return true
  }
  return false
}

function updateSelection(view, selection, origin) {
  if (!view.focused) view.focus()
  let tr = view.state.tr.setSelection(selection)
  if (origin == "pointer") tr.setMeta("pointer", true)
  view.dispatch(tr)
}

function selectClickedLeaf(view, inside) {
  if (inside == -1) return false
  let $pos = view.state.doc.resolve(inside), node = $pos.nodeAfter
  if (node && node.isAtom && NodeSelection.isSelectable(node)) {
    updateSelection(view, new NodeSelection($pos), "pointer")
    return true
  }
  return false
}

function selectClickedNode(view, inside) {
  if (inside == -1) return false
  let sel = view.state.selection, selectedNode, selectAt
  if (sel instanceof NodeSelection) selectedNode = sel.node

  let $pos = view.state.doc.resolve(inside)
  for (let i = $pos.depth + 1; i > 0; i--) {
    let node = i > $pos.depth ? $pos.nodeAfter : $pos.node(i)
    if (NodeSelection.isSelectable(node)) {
      if (selectedNode && sel.$from.depth > 0 &&
          i >= sel.$from.depth && $pos.before(sel.$from.depth + 1) == sel.$from.pos)
        selectAt = $pos.before(sel.$from.depth)
      else
        selectAt = $pos.before(i)
      break
    }
  }

  if (selectAt != null) {
    updateSelection(view, NodeSelection.create(view.state.doc, selectAt), "pointer")
    return true
  } else {
    return false
  }
}

function handleSingleClick(view, pos, inside, event, selectNode) {
  return runHandlerOnContext(view, "handleClickOn", pos, inside, event) ||
    view.someProp("handleClick", f => f(view, pos, event)) ||
    (selectNode ? selectClickedNode(view, inside) : selectClickedLeaf(view, inside))
}

function handleDoubleClick(view, pos, inside, event) {
  return runHandlerOnContext(view, "handleDoubleClickOn", pos, inside, event) ||
    view.someProp("handleDoubleClick", f => f(view, pos, event))
}

function handleTripleClick(view, pos, inside, event) {
  return runHandlerOnContext(view, "handleTripleClickOn", pos, inside, event) ||
    view.someProp("handleTripleClick", f => f(view, pos, event)) ||
    defaultTripleClick(view, inside)
}

function defaultTripleClick(view, inside) {
  let doc = view.state.doc
  if (inside == -1) {
    if (doc.inlineContent) {
      updateSelection(view, TextSelection.create(doc, 0, doc.content.size), "pointer")
      return true
    }
    return false
  }

  let $pos = doc.resolve(inside)
  for (let i = $pos.depth + 1; i > 0; i--) {
    let node = i > $pos.depth ? $pos.nodeAfter : $pos.node(i)
    let nodePos = $pos.before(i)
    if (node.inlineContent)
      updateSelection(view, TextSelection.create(doc, nodePos + 1, nodePos + 1 + node.content.size), "pointer")
    else if (NodeSelection.isSelectable(node))
      updateSelection(view, NodeSelection.create(doc, nodePos), "pointer")
    else
      continue
    return true
  }
}

function forceDOMFlush(view) {
  return endComposition(view)
}

const selectNodeModifier = browser.mac ? "metaKey" : "ctrlKey"

handlers.mousedown = (view, event) => {
  view.shiftKey = event.shiftKey
  let flushed = forceDOMFlush(view)
  let now = Date.now(), type = "singleClick"
  if (now - view.lastClick.time < 500 && isNear(event, view.lastClick) && !event[selectNodeModifier]) {
    if (view.lastClick.type == "singleClick") type = "doubleClick"
    else if (view.lastClick.type == "doubleClick") type = "tripleClick"
  }
  view.lastClick = {time: now, x: event.clientX, y: event.clientY, type}

  let pos = view.posAtCoords(eventCoords(event))
  if (!pos) return

  if (type == "singleClick") {
    if (view.mouseDown) view.mouseDown.done()
    view.mouseDown = new MouseDown(view, pos, event, flushed)
  } else if ((type == "doubleClick" ? handleDoubleClick : handleTripleClick)(view, pos.pos, pos.inside, event)) {
    event.preventDefault()
  } else {
    setSelectionOrigin(view, "pointer")
  }
}

class MouseDown {
  constructor(view, pos, event, flushed) {
    this.view = view
    this.startDoc = view.state.doc
    this.pos = pos
    this.event = event
    this.flushed = flushed
    this.selectNode = event[selectNodeModifier]
    this.allowDefault = event.shiftKey

    let targetNode, targetPos
    if (pos.inside > -1) {
      targetNode = view.state.doc.nodeAt(pos.inside)
      targetPos = pos.inside
    } else {
      let $pos = view.state.doc.resolve(pos.pos)
      targetNode = $pos.parent
      targetPos = $pos.depth ? $pos.before() : 0
    }

    this.mightDrag = null

    const target = flushed ? null : event.target
    const targetDesc = target ? view.docView.nearestDesc(target, true) : null
    this.target = targetDesc ? targetDesc.dom : null

    if (targetNode.type.spec.draggable && targetNode.type.spec.selectable !== false ||
        view.state.selection instanceof NodeSelection && targetPos == view.state.selection.from)
      this.mightDrag = {node: targetNode,
                        pos: targetPos,
                        addAttr: this.target && !this.target.draggable,
                        setUneditable: this.target && browser.gecko && !this.target.hasAttribute("contentEditable")}

    if (this.target && this.mightDrag && (this.mightDrag.addAttr || this.mightDrag.setUneditable)) {
      this.view.domObserver.stop()
      if (this.mightDrag.addAttr) this.target.draggable = true
      if (this.mightDrag.setUneditable)
        setTimeout(() => {
          if (this.view.mouseDown == this) this.target.setAttribute("contentEditable", "false")
        }, 20)
      this.view.domObserver.start()
    }

    view.root.addEventListener("mouseup", this.up = this.up.bind(this))
    view.root.addEventListener("mousemove", this.move = this.move.bind(this))
    setSelectionOrigin(view, "pointer")
  }

  done() {
    this.view.root.removeEventListener("mouseup", this.up)
    this.view.root.removeEventListener("mousemove", this.move)
    if (this.mightDrag && this.target) {
      this.view.domObserver.stop()
      if (this.mightDrag.addAttr) this.target.removeAttribute("draggable")
      if (this.mightDrag.setUneditable) this.target.removeAttribute("contentEditable")
      this.view.domObserver.start()
    }
    this.view.mouseDown = null
  }

  up(event) {
    this.done()

    if (!this.view.dom.contains(event.target.nodeType == 3 ? event.target.parentNode : event.target))
      return

    let pos = this.pos
    if (this.view.state.doc != this.startDoc) pos = this.view.posAtCoords(eventCoords(event))

    if (this.allowDefault || !pos) {
      setSelectionOrigin(this.view, "pointer")
    } else if (handleSingleClick(this.view, pos.pos, pos.inside, event, this.selectNode)) {
      event.preventDefault()
    } else if (this.flushed ||
               // Safari ignores clicks on draggable elements
               (browser.safari && this.mightDrag && !this.mightDrag.node.isAtom) ||
               // Chrome will sometimes treat a node selection as a
               // cursor, but still report that the node is selected
               // when asked through getSelection. You'll then get a
               // situation where clicking at the point where that
               // (hidden) cursor is doesn't change the selection, and
               // thus doesn't get a reaction from ProseMirror. This
               // works around that.
               (browser.chrome && !(this.view.state.selection instanceof TextSelection) &&
                (pos.pos == this.view.state.selection.from || pos.pos == this.view.state.selection.to))) {
      updateSelection(this.view, Selection.near(this.view.state.doc.resolve(pos.pos)), "pointer")
      event.preventDefault()
    } else {
      setSelectionOrigin(this.view, "pointer")
    }
  }

  move(event) {
    if (!this.allowDefault && (Math.abs(this.event.x - event.clientX) > 4 ||
                               Math.abs(this.event.y - event.clientY) > 4))
      this.allowDefault = true
    setSelectionOrigin(this.view, "pointer")
    if (event.buttons == 0) this.done()
  }
}

handlers.touchdown = view => {
  forceDOMFlush(view)
  setSelectionOrigin(view, "pointer")
}

handlers.contextmenu = view => forceDOMFlush(view)

function inOrNearComposition(view, event) {
  if (view.composing) return true
  // See https://www.stum.de/2016/06/24/handling-ime-events-in-javascript/.
  // On Japanese input method editors (IMEs), the Enter key is used to confirm character
  // selection. On Safari, when Enter is pressed, compositionend and keydown events are
  // emitted. The keydown event triggers newline insertion, which we don't want.
  // This method returns true if the keydown event should be ignored.
  // We only ignore it once, as pressing Enter a second time *should* insert a newline.
  // Furthermore, the keydown event timestamp must be close to the compositionEndedAt timestamp.
  // This guards against the case where compositionend is triggered without the keyboard
  // (e.g. character confirmation may be done with the mouse), and keydown is triggered
  // afterwards- we wouldn't want to ignore the keydown event in this case.
  if (browser.safari && Math.abs(event.timeStamp - view.compositionEndedAt) < 500) {
    view.compositionEndedAt = -2e8
    return true
  }
  return false
}

// Drop active composition after 5 seconds of inactivity on Android
const timeoutComposition = browser.android ? 5000 : -1

editHandlers.compositionstart = editHandlers.compositionupdate = view => {
  if (!view.composing) {
    view.domObserver.flush()
    let {state} = view, $pos = state.selection.$from
    if (state.selection.empty &&
        (state.storedMarks ||
         (!$pos.textOffset && $pos.parentOffset && $pos.nodeBefore.marks.some(m => m.type.spec.inclusive === false)))) {
      // Need to wrap the cursor in mark nodes different from the ones in the DOM context
      view.markCursor = view.state.storedMarks || $pos.marks()
      endComposition(view, true)
      view.markCursor = null
    } else {
      endComposition(view)
      // In firefox, if the cursor is after but outside a marked node,
      // the inserted text won't inherit the marks. So this moves it
      // inside if necessary.
      if (browser.gecko && state.selection.empty && $pos.parentOffset && !$pos.textOffset && $pos.nodeBefore.marks.length) {
        let sel = view.root.getSelection()
        for (let node = sel.focusNode, offset = sel.focusOffset; node && node.nodeType == 1 && offset != 0;) {
          let before = offset < 0 ? node.lastChild : node.childNodes[offset - 1]
          if (!before) break
          if (before.nodeType == 3) {
            sel.collapse(before, before.nodeValue.length)
            break
          } else {
            node = before
            offset = -1
          }
        }
      }
    }
    view.composing = true
  }
  scheduleComposeEnd(view, timeoutComposition)
}

editHandlers.compositionend = (view, event) => {
  if (view.composing) {
    view.composing = false
    view.compositionEndedAt = event.timeStamp
    scheduleComposeEnd(view, 20)
  }
}

function scheduleComposeEnd(view, delay) {
  clearTimeout(view.composingTimeout)
  if (delay > -1) view.composingTimeout = setTimeout(() => endComposition(view), delay)
}

export function clearComposition(view) {
  view.composing = false
  while (view.compositionNodes.length > 0) view.compositionNodes.pop().markParentsDirty()
}

export function endComposition(view, forceUpdate) {
  view.domObserver.forceFlush()
  clearComposition(view)
  if (forceUpdate || view.docView.dirty) {
    let sel = selectionFromDOM(view)
    if (sel && !sel.eq(view.state.selection)) view.dispatch(view.state.tr.setSelection(sel))
    else view.updateState(view.state)
    return true
  }
  return false
}

function captureCopy(view, dom) {
  // The extra wrapper is somehow necessary on IE/Edge to prevent the
  // content from being mangled when it is put onto the clipboard
  if (!view.dom.parentNode) return
  let wrap = view.dom.parentNode.appendChild(document.createElement("div"))
  wrap.appendChild(dom)
  wrap.style.cssText = "position: fixed; left: -10000px; top: 10px"
  let sel = getSelection(), range = document.createRange()
  range.selectNodeContents(dom)
  // Done because IE will fire a selectionchange moving the selection
  // to its start when removeAllRanges is called and the editor still
  // has focus (which will mess up the editor's selection state).
  view.dom.blur()
  sel.removeAllRanges()
  sel.addRange(range)
  setTimeout(() => {
    if (wrap.parentNode) wrap.parentNode.removeChild(wrap)
    view.focus()
  }, 50)
}

// This is very crude, but unfortunately both these browsers _pretend_
// that they have a clipboard API—all the objects and methods are
// there, they just don't work, and they are hard to test.
const brokenClipboardAPI = (browser.ie && browser.ie_version < 15) ||
      (browser.ios && browser.webkit_version < 604)

handlers.copy = editHandlers.cut = (view, e) => {
  let sel = view.state.selection, cut = e.type == "cut"
  if (sel.empty) return

  // IE and Edge's clipboard interface is completely broken
  let data = brokenClipboardAPI ? null : e.clipboardData
  let slice = sel.content(), {dom, text} = serializeForClipboard(view, slice)
  if (data) {
    e.preventDefault()
    data.clearData()
    data.setData("text/html", dom.innerHTML)
    data.setData("text/plain", text)
  } else {
    captureCopy(view, dom)
  }
  if (cut) view.dispatch(view.state.tr.deleteSelection().scrollIntoView().setMeta("uiEvent", "cut"))
}

function sliceSingleNode(slice) {
  return slice.openStart == 0 && slice.openEnd == 0 && slice.content.childCount == 1 ? slice.content.firstChild : null
}

function capturePaste(view, e) {
  if (!view.dom.parentNode) return
  let plainText = view.shiftKey || view.state.selection.$from.parent.type.spec.code
  let target = view.dom.parentNode.appendChild(document.createElement(plainText ? "textarea" : "div"))
  if (!plainText) target.contentEditable = "true"
  target.style.cssText = "position: fixed; left: -10000px; top: 10px"
  target.focus()
  setTimeout(() => {
    view.focus()
    if (target.parentNode) target.parentNode.removeChild(target)
    if (plainText) doPaste(view, target.value, null, e)
    else doPaste(view, target.textContent, target.innerHTML, e)
  }, 50)
}

function doPaste(view, text, html, e) {
  let slice = parseFromClipboard(view, text, html, view.shiftKey, view.state.selection.$from)
  if (view.someProp("handlePaste", f => f(view, e, slice || Slice.empty))) return true
  if (!slice) return false

  let singleNode = sliceSingleNode(slice)
  let tr = singleNode ? view.state.tr.replaceSelectionWith(singleNode, view.shiftKey) : view.state.tr.replaceSelection(slice)
  view.dispatch(tr.scrollIntoView().setMeta("paste", true).setMeta("uiEvent", "paste"))
  return true
}

editHandlers.paste = (view, e) => {
  let data = brokenClipboardAPI ? null : e.clipboardData
  if (data && doPaste(view, data.getData("text/plain"), data.getData("text/html"), e)) e.preventDefault()
  else capturePaste(view, e)
}

class Dragging {
  constructor(slice, move) {
    this.slice = slice
    this.move = move
  }
}

const dragCopyModifier = browser.mac ? "altKey" : "ctrlKey"

handlers.dragstart = (view, e) => {
  let mouseDown = view.mouseDown
  if (mouseDown) mouseDown.done()
  if (!e.dataTransfer) return

  let sel = view.state.selection
  let pos = sel.empty ? null : view.posAtCoords(eventCoords(e))
  if (pos && pos.pos >= sel.from && pos.pos <= (sel instanceof NodeSelection ? sel.to - 1: sel.to)) {
    // In selection
  } else if (mouseDown && mouseDown.mightDrag) {
    view.dispatch(view.state.tr.setSelection(NodeSelection.create(view.state.doc, mouseDown.mightDrag.pos)))
  } else if (e.target && e.target.nodeType == 1) {
    let desc = view.docView.nearestDesc(e.target, true)
    if (!desc || !desc.node.type.spec.draggable || desc == view.docView) return
    view.dispatch(view.state.tr.setSelection(NodeSelection.create(view.state.doc, desc.posBefore)))
  }
  let slice = view.state.selection.content(), {dom, text} = serializeForClipboard(view, slice)
  e.dataTransfer.clearData()
  e.dataTransfer.setData(brokenClipboardAPI ? "Text" : "text/html", dom.innerHTML)
  // See https://github.com/ProseMirror/prosemirror/issues/1156
  e.dataTransfer.effectAllowed = "copyMove"
  if (!brokenClipboardAPI) e.dataTransfer.setData("text/plain", text)
  view.dragging = new Dragging(slice, !e[dragCopyModifier])
}

handlers.dragend = view => {
  let dragging = view.dragging
  window.setTimeout(() => {
    if (view.dragging == dragging)  view.dragging = null
  }, 50)
}

editHandlers.dragover = editHandlers.dragenter = (_, e) => e.preventDefault()

editHandlers.drop = (view, e) => {
  let dragging = view.dragging
  view.dragging = null

  if (!e.dataTransfer) return

  let eventPos = view.posAtCoords(eventCoords(e))
  if (!eventPos) return
  let $mouse = view.state.doc.resolve(eventPos.pos)
  if (!$mouse) return
  let slice = dragging && dragging.slice ||
      parseFromClipboard(view, e.dataTransfer.getData(brokenClipboardAPI ? "Text" : "text/plain"),
                         brokenClipboardAPI ? null : e.dataTransfer.getData("text/html"), false, $mouse)
  let move = dragging && !e[dragCopyModifier]
  if (view.someProp("handleDrop", f => f(view, e, slice || Slice.empty, move))) {
    e.preventDefault()
    return
  }
  if (!slice) return

  e.preventDefault()
  let insertPos = slice ? dropPoint(view.state.doc, $mouse.pos, slice) : $mouse.pos
  if (insertPos == null) insertPos = $mouse.pos

  let tr = view.state.tr
  if (move) tr.deleteSelection()

  let pos = tr.mapping.map(insertPos)
  let isNode = slice.openStart == 0 && slice.openEnd == 0 && slice.content.childCount == 1
  let beforeInsert = tr.doc
  if (isNode)
    tr.replaceRangeWith(pos, pos, slice.content.firstChild)
  else
    tr.replaceRange(pos, pos, slice)
  if (tr.doc.eq(beforeInsert)) return

  let $pos = tr.doc.resolve(pos)
  if (isNode && NodeSelection.isSelectable(slice.content.firstChild) &&
      $pos.nodeAfter && $pos.nodeAfter.sameMarkup(slice.content.firstChild)) {
    tr.setSelection(new NodeSelection($pos))
  } else {
    let end = tr.mapping.map(insertPos)
    tr.mapping.maps[tr.mapping.maps.length - 1].forEach((_from, _to, _newFrom, newTo) => end = newTo)
    tr.setSelection(selectionBetween(view, $pos, tr.doc.resolve(end)))
  }
  view.focus()
  view.dispatch(tr.setMeta("uiEvent", "drop"))
}

handlers.focus = view => {
  if (!view.focused) {
    view.domObserver.stop()
    view.dom.classList.add("ProseMirror-focused")
    view.domObserver.start()
    view.focused = true
    setTimeout(() => {
      if (view.docView && view.hasFocus() && !view.domObserver.currentSelection.eq(view.root.getSelection()))
        selectionToDOM(view)
    }, 20)
  }
}

handlers.blur = view => {
  if (view.focused) {
    view.domObserver.stop()
    view.dom.classList.remove("ProseMirror-focused")
    view.domObserver.start()
    view.domObserver.currentSelection.set({})
    view.focused = false
  }
}

handlers.beforeinput = (view, event) => {
  // We should probably do more with beforeinput events, but support
  // is so spotty that I'm still waiting to see where they are going.

  // Very specific hack to deal with backspace sometimes failing on
  // Chrome Android when after an uneditable node.
  if (browser.chrome && browser.android && event.inputType == "deleteContentBackward") {
    let {domChangeCount} = view
    setTimeout(() => {
      if (view.domChangeCount != domChangeCount) return // Event already had some effect
      // This bug tends to close the virtual keyboard, so we refocus
      view.dom.blur()
      view.focus()
      if (view.someProp("handleKeyDown", f => f(view, keyEvent(8, "Backspace")))) return
      let {$cursor} = view.state.selection
      // Crude approximation of backspace behavior when no command handled it
      if ($cursor && $cursor.pos > 0) view.dispatch(view.state.tr.delete($cursor.pos - 1, $cursor.pos).scrollIntoView())
    }, 50)
  }
}

// Make sure all handlers get registered
for (let prop in editHandlers) handlers[prop] = editHandlers[prop]
