import {Selection, NodeSelection, TextSelection} from "prosemirror-state"
import {dropPoint} from "prosemirror-transform"
import {Slice, Node} from "prosemirror-model"

import * as browser from "./browser"
import {captureKeyDown} from "./capturekeys"
import {parseFromClipboard, serializeForClipboard} from "./clipboard"
import {selectionBetween, selectionToDOM, selectionFromDOM} from "./selection"
import {keyEvent, DOMNode, textNodeBefore, textNodeAfter} from "./dom"
import {EditorView} from "./index"
import {ViewDesc} from "./viewdesc"

// A collection of DOM events that occur within the editor, and callback functions
// to invoke when the event fires.
const handlers: {[event: string]: (view: EditorView, event: Event) => void} = {}
const editHandlers: {[event: string]: (view: EditorView, event: Event) => void} = {}
const passiveHandlers: Record<string, boolean> = {touchstart: true, touchmove: true}

export class InputState {
  shiftKey = false
  mouseDown: MouseDown | null = null
  lastKeyCode: number | null = null
  lastKeyCodeTime = 0
  lastClick = {time: 0, x: 0, y: 0, type: ""}
  lastSelectionOrigin: string | null = null
  lastSelectionTime = 0
  lastIOSEnter = 0
  lastIOSEnterFallbackTimeout = -1
  lastFocus = 0
  lastTouch = 0
  lastAndroidDelete = 0
  composing = false
  compositionNode: Text | null = null
  composingTimeout = -1
  compositionNodes: ViewDesc[] = []
  compositionEndedAt = -2e8
  compositionID = 1
  // Set to a composition ID when there are pending changes at compositionend
  compositionPendingChanges = 0
  domChangeCount = 0
  eventHandlers: {[event: string]: (event: Event) => void} = Object.create(null)
  hideSelectionGuard: (() => void) | null = null
}

export function initInput(view: EditorView) {
  for (let event in handlers) {
    let handler = handlers[event]
    view.dom.addEventListener(event, view.input.eventHandlers[event] = (event: Event) => {
      if (eventBelongsToView(view, event) && !runCustomHandler(view, event) &&
          (view.editable || !(event.type in editHandlers)))
        handler(view, event)
    }, passiveHandlers[event] ? {passive: true} : undefined)
  }
  // On Safari, for reasons beyond my understanding, adding an input
  // event handler makes an issue where the composition vanishes when
  // you press enter go away.
  if (browser.safari) view.dom.addEventListener("input", () => null)

  ensureListeners(view)
}

function setSelectionOrigin(view: EditorView, origin: string) {
  view.input.lastSelectionOrigin = origin
  view.input.lastSelectionTime = Date.now()
}

export function destroyInput(view: EditorView) {
  view.domObserver.stop()
  for (let type in view.input.eventHandlers)
    view.dom.removeEventListener(type, view.input.eventHandlers[type])
  clearTimeout(view.input.composingTimeout)
  clearTimeout(view.input.lastIOSEnterFallbackTimeout)
}

export function ensureListeners(view: EditorView) {
  view.someProp("handleDOMEvents", currentHandlers => {
    for (let type in currentHandlers) if (!view.input.eventHandlers[type])
      view.dom.addEventListener(type, view.input.eventHandlers[type] = event => runCustomHandler(view, event))
  })
}

function runCustomHandler(view: EditorView, event: Event) {
  return view.someProp("handleDOMEvents", handlers => {
    let handler = handlers[event.type]
    return handler ? handler(view, event) || event.defaultPrevented : false
  })
}

function eventBelongsToView(view: EditorView, event: Event) {
  if (!event.bubbles) return true
  if (event.defaultPrevented) return false
  for (let node = event.target as DOMNode; node != view.dom; node = node.parentNode!)
    if (!node || node.nodeType == 11 ||
        (node.pmViewDesc && node.pmViewDesc.stopEvent(event)))
      return false
  return true
}

export function dispatchEvent(view: EditorView, event: Event) {
  if (!runCustomHandler(view, event) && handlers[event.type] &&
      (view.editable || !(event.type in editHandlers)))
    handlers[event.type](view, event)
}

editHandlers.keydown = (view: EditorView, _event: Event) => {
  let event = _event as KeyboardEvent
  view.input.shiftKey = event.keyCode == 16 || event.shiftKey
  if (inOrNearComposition(view, event)) return
  view.input.lastKeyCode = event.keyCode
  view.input.lastKeyCodeTime = Date.now()
  // Suppress enter key events on Chrome Android, because those tend
  // to be part of a confused sequence of composition events fired,
  // and handling them eagerly tends to corrupt the input.
  if (browser.android && browser.chrome && event.keyCode == 13) return
  if (event.keyCode != 229) view.domObserver.forceFlush()

  // On iOS, if we preventDefault enter key presses, the virtual
  // keyboard gets confused. So the hack here is to set a flag that
  // makes the DOM change code recognize that what just happens should
  // be replaced by whatever the Enter key handlers do.
  if (browser.ios && event.keyCode == 13 && !event.ctrlKey && !event.altKey && !event.metaKey) {
    let now = Date.now()
    view.input.lastIOSEnter = now
    view.input.lastIOSEnterFallbackTimeout = setTimeout(() => {
      if (view.input.lastIOSEnter == now) {
        view.someProp("handleKeyDown", f => f(view, keyEvent(13, "Enter")))
        view.input.lastIOSEnter = 0
      }
    }, 200)
  } else if (view.someProp("handleKeyDown", f => f(view, event)) || captureKeyDown(view, event)) {
    event.preventDefault()
  } else {
    setSelectionOrigin(view, "key")
  }
}

editHandlers.keyup = (view, event) => {
  if ((event as KeyboardEvent).keyCode == 16) view.input.shiftKey = false
}

editHandlers.keypress = (view, _event) => {
  let event = _event as KeyboardEvent
  if (inOrNearComposition(view, event) || !event.charCode ||
      event.ctrlKey && !event.altKey || browser.mac && event.metaKey) return

  if (view.someProp("handleKeyPress", f => f(view, event))) {
    event.preventDefault()
    return
  }

  let sel = view.state.selection
  if (!(sel instanceof TextSelection) || !sel.$from.sameParent(sel.$to)) {
    let text = String.fromCharCode(event.charCode)
    if (!/[\r\n]/.test(text) && !view.someProp("handleTextInput", f => f(view, sel.$from.pos, sel.$to.pos, text)))
      view.dispatch(view.state.tr.insertText(text).scrollIntoView())
    event.preventDefault()
  }
}

function eventCoords(event: MouseEvent) { return {left: event.clientX, top: event.clientY} }

function isNear(event: MouseEvent, click: {x: number, y: number}) {
  let dx = click.x - event.clientX, dy = click.y - event.clientY
  return dx * dx + dy * dy < 100
}

function runHandlerOnContext(
  view: EditorView,
  propName: "handleClickOn" | "handleDoubleClickOn" | "handleTripleClickOn",
  pos: number,
  inside: number,
  event: MouseEvent
) {
  if (inside == -1) return false
  let $pos = view.state.doc.resolve(inside)
  for (let i = $pos.depth + 1; i > 0; i--) {
    if (view.someProp(propName, f => i > $pos.depth ? f(view, pos, $pos.nodeAfter!, $pos.before(i), event, true)
                                                    : f(view, pos, $pos.node(i), $pos.before(i), event, false)))
      return true
  }
  return false
}

function updateSelection(view: EditorView, selection: Selection, origin: string) {
  if (!view.focused) view.focus()
  if (view.state.selection.eq(selection)) return
  let tr = view.state.tr.setSelection(selection)
  if (origin == "pointer") tr.setMeta("pointer", true)
  view.dispatch(tr)
}

function selectClickedLeaf(view: EditorView, inside: number) {
  if (inside == -1) return false
  let $pos = view.state.doc.resolve(inside), node = $pos.nodeAfter
  if (node && node.isAtom && NodeSelection.isSelectable(node)) {
    updateSelection(view, new NodeSelection($pos), "pointer")
    return true
  }
  return false
}

function selectClickedNode(view: EditorView, inside: number) {
  if (inside == -1) return false
  let sel = view.state.selection, selectedNode, selectAt
  if (sel instanceof NodeSelection) selectedNode = sel.node

  let $pos = view.state.doc.resolve(inside)
  for (let i = $pos.depth + 1; i > 0; i--) {
    let node = i > $pos.depth ? $pos.nodeAfter! : $pos.node(i)
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

function handleSingleClick(view: EditorView, pos: number, inside: number, event: MouseEvent, selectNode: boolean) {
  return runHandlerOnContext(view, "handleClickOn", pos, inside, event) ||
    view.someProp("handleClick", f => f(view, pos, event)) ||
    (selectNode ? selectClickedNode(view, inside) : selectClickedLeaf(view, inside))
}

function handleDoubleClick(view: EditorView, pos: number, inside: number, event: MouseEvent) {
  return runHandlerOnContext(view, "handleDoubleClickOn", pos, inside, event) ||
    view.someProp("handleDoubleClick", f => f(view, pos, event))
}

function handleTripleClick(view: EditorView, pos: number, inside: number, event: MouseEvent) {
  return runHandlerOnContext(view, "handleTripleClickOn", pos, inside, event) ||
    view.someProp("handleTripleClick", f => f(view, pos, event)) ||
    defaultTripleClick(view, inside, event)
}

function defaultTripleClick(view: EditorView, inside: number, event: MouseEvent) {
  if (event.button != 0) return false
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
    let node = i > $pos.depth ? $pos.nodeAfter! : $pos.node(i)
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

function forceDOMFlush(view: EditorView) {
  return endComposition(view)
}

const selectNodeModifier: keyof MouseEvent = browser.mac ? "metaKey" : "ctrlKey"

handlers.mousedown = (view, _event) => {
  let event = _event as MouseEvent
  view.input.shiftKey = event.shiftKey
  let flushed = forceDOMFlush(view)
  let now = Date.now(), type = "singleClick"
  if (now - view.input.lastClick.time < 500 && isNear(event, view.input.lastClick) && !event[selectNodeModifier]) {
    if (view.input.lastClick.type == "singleClick") type = "doubleClick"
    else if (view.input.lastClick.type == "doubleClick") type = "tripleClick"
  }
  view.input.lastClick = {time: now, x: event.clientX, y: event.clientY, type}

  let pos = view.posAtCoords(eventCoords(event))
  if (!pos) return

  if (type == "singleClick") {
    if (view.input.mouseDown) view.input.mouseDown.done()
    view.input.mouseDown = new MouseDown(view, pos, event, !!flushed)
  } else if ((type == "doubleClick" ? handleDoubleClick : handleTripleClick)(view, pos.pos, pos.inside, event)) {
    event.preventDefault()
  } else {
    setSelectionOrigin(view, "pointer")
  }
}

class MouseDown {
  startDoc: Node
  selectNode: boolean
  allowDefault: boolean
  delayedSelectionSync = false
  mightDrag: {node: Node, pos: number, addAttr: boolean, setUneditable: boolean} | null = null
  target: HTMLElement | null

  constructor(
    readonly view: EditorView,
    readonly pos: {pos: number, inside: number},
    readonly event: MouseEvent,
    readonly flushed: boolean
  ) {
    this.startDoc = view.state.doc
    this.selectNode = !!event[selectNodeModifier]
    this.allowDefault = event.shiftKey

    let targetNode: Node, targetPos
    if (pos.inside > -1) {
      targetNode = view.state.doc.nodeAt(pos.inside)!
      targetPos = pos.inside
    } else {
      let $pos = view.state.doc.resolve(pos.pos)
      targetNode = $pos.parent
      targetPos = $pos.depth ? $pos.before() : 0
    }

    const target = flushed ? null : event.target as HTMLElement
    const targetDesc = target ? view.docView.nearestDesc(target, true) : null
    this.target = targetDesc && targetDesc.dom.nodeType == 1 ? targetDesc.dom as HTMLElement : null

    let {selection} = view.state
    if (event.button == 0 &&
        targetNode.type.spec.draggable && targetNode.type.spec.selectable !== false ||
        selection instanceof NodeSelection && selection.from <= targetPos && selection.to > targetPos)
      this.mightDrag = {
        node: targetNode,
        pos: targetPos,
        addAttr: !!(this.target && !this.target.draggable),
        setUneditable: !!(this.target && browser.gecko && !this.target.hasAttribute("contentEditable"))
      }

    if (this.target && this.mightDrag && (this.mightDrag.addAttr || this.mightDrag.setUneditable)) {
      this.view.domObserver.stop()
      if (this.mightDrag.addAttr) this.target.draggable = true
      if (this.mightDrag.setUneditable)
        setTimeout(() => {
          if (this.view.input.mouseDown == this) this.target!.setAttribute("contentEditable", "false")
        }, 20)
      this.view.domObserver.start()
    }

    view.root.addEventListener("mouseup", this.up = this.up.bind(this) as any)
    view.root.addEventListener("mousemove", this.move = this.move.bind(this) as any)
    setSelectionOrigin(view, "pointer")
  }

  done() {
    this.view.root.removeEventListener("mouseup", this.up as any)
    this.view.root.removeEventListener("mousemove", this.move as any)
    if (this.mightDrag && this.target) {
      this.view.domObserver.stop()
      if (this.mightDrag.addAttr) this.target.removeAttribute("draggable")
      if (this.mightDrag.setUneditable) this.target.removeAttribute("contentEditable")
      this.view.domObserver.start()
    }
    if (this.delayedSelectionSync) setTimeout(() => selectionToDOM(this.view))
    this.view.input.mouseDown = null
  }

  up(event: MouseEvent) {
    this.done()

    if (!this.view.dom.contains(event.target as HTMLElement))
      return

    let pos: {pos: number, inside: number} | null = this.pos
    if (this.view.state.doc != this.startDoc) pos = this.view.posAtCoords(eventCoords(event))

    this.updateAllowDefault(event)
    if (this.allowDefault || !pos) {
      setSelectionOrigin(this.view, "pointer")
    } else if (handleSingleClick(this.view, pos.pos, pos.inside, event, this.selectNode)) {
      event.preventDefault()
    } else if (event.button == 0 &&
               (this.flushed ||
                // Safari ignores clicks on draggable elements
                (browser.safari && this.mightDrag && !this.mightDrag.node.isAtom) ||
                // Chrome will sometimes treat a node selection as a
                // cursor, but still report that the node is selected
                // when asked through getSelection. You'll then get a
                // situation where clicking at the point where that
                // (hidden) cursor is doesn't change the selection, and
                // thus doesn't get a reaction from ProseMirror. This
                // works around that.
                (browser.chrome && !this.view.state.selection.visible &&
                 Math.min(Math.abs(pos.pos - this.view.state.selection.from),
                          Math.abs(pos.pos - this.view.state.selection.to)) <= 2))) {
      updateSelection(this.view, Selection.near(this.view.state.doc.resolve(pos.pos)), "pointer")
      event.preventDefault()
    } else {
      setSelectionOrigin(this.view, "pointer")
    }
  }

  move(event: MouseEvent) {
    this.updateAllowDefault(event)
    setSelectionOrigin(this.view, "pointer")
    if (event.buttons == 0) this.done()
  }

  updateAllowDefault(event: MouseEvent) {
    if (!this.allowDefault && (Math.abs(this.event.x - event.clientX) > 4 ||
        Math.abs(this.event.y - event.clientY) > 4))
      this.allowDefault = true
  }
}

handlers.touchstart = view => {
  view.input.lastTouch = Date.now()
  forceDOMFlush(view)
  setSelectionOrigin(view, "pointer")
}

handlers.touchmove = view => {
  view.input.lastTouch = Date.now()
  setSelectionOrigin(view, "pointer")
}

handlers.contextmenu = view => forceDOMFlush(view)

function inOrNearComposition(view: EditorView, event: Event) {
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
  if (browser.safari && Math.abs(event.timeStamp - view.input.compositionEndedAt) < 500) {
    view.input.compositionEndedAt = -2e8
    return true
  }
  return false
}

// Drop active composition after 5 seconds of inactivity on Android
const timeoutComposition = browser.android ? 5000 : -1

editHandlers.compositionstart = editHandlers.compositionupdate = view => {
  if (!view.composing) {
    view.domObserver.flush()
    let {state} = view, $pos = state.selection.$to
    if (state.selection instanceof TextSelection &&
        (state.storedMarks ||
         (!$pos.textOffset && $pos.parentOffset && $pos.nodeBefore!.marks.some(m => m.type.spec.inclusive === false)))) {
      // Need to wrap the cursor in mark nodes different from the ones in the DOM context
      view.markCursor = view.state.storedMarks || $pos.marks()
      endComposition(view, true)
      view.markCursor = null
    } else {
      endComposition(view, !state.selection.empty)
      // In firefox, if the cursor is after but outside a marked node,
      // the inserted text won't inherit the marks. So this moves it
      // inside if necessary.
      if (browser.gecko && state.selection.empty && $pos.parentOffset && !$pos.textOffset && $pos.nodeBefore!.marks.length) {
        let sel = view.domSelectionRange()
        for (let node = sel.focusNode, offset = sel.focusOffset; node && node.nodeType == 1 && offset != 0;) {
          let before = offset < 0 ? node.lastChild : node.childNodes[offset - 1]
          if (!before) break
          if (before.nodeType == 3) {
            let sel = view.domSelection()
            if (sel) sel.collapse(before, before.nodeValue!.length)
            break
          } else {
            node = before
            offset = -1
          }
        }
      }
    }
    view.input.composing = true
  }
  scheduleComposeEnd(view, timeoutComposition)
}

editHandlers.compositionend = (view, event) => {
  if (view.composing) {
    view.input.composing = false
    view.input.compositionEndedAt = event.timeStamp
    view.input.compositionPendingChanges = view.domObserver.pendingRecords().length ? view.input.compositionID : 0
    view.input.compositionNode = null
    if (view.input.compositionPendingChanges) Promise.resolve().then(() => view.domObserver.flush())
    view.input.compositionID++
    scheduleComposeEnd(view, 20)
  }
}

function scheduleComposeEnd(view: EditorView, delay: number) {
  clearTimeout(view.input.composingTimeout)
  if (delay > -1) view.input.composingTimeout = setTimeout(() => endComposition(view), delay)
}

export function clearComposition(view: EditorView) {
  if (view.composing) {
    view.input.composing = false
    view.input.compositionEndedAt = timestampFromCustomEvent()
  }
  while (view.input.compositionNodes.length > 0) view.input.compositionNodes.pop()!.markParentsDirty()
}

export function findCompositionNode(view: EditorView) {
  let sel = view.domSelectionRange()
  if (!sel.focusNode) return null
  let textBefore = textNodeBefore(sel.focusNode, sel.focusOffset)
  let textAfter = textNodeAfter(sel.focusNode, sel.focusOffset)
  if (textBefore && textAfter && textBefore != textAfter) {
    let descAfter = textAfter.pmViewDesc, lastChanged = view.domObserver.lastChangedTextNode
    if (textBefore == lastChanged || textAfter == lastChanged) return lastChanged
    if (!descAfter || !descAfter.isText(textAfter.nodeValue!)) {
      return textAfter
    } else if (view.input.compositionNode == textAfter) {
      let descBefore = textBefore.pmViewDesc
      if (!(!descBefore || !descBefore.isText(textBefore.nodeValue!)))
        return textAfter
    }
  }
  return textBefore || textAfter
}

function timestampFromCustomEvent() {
  let event = document.createEvent("Event")
  event.initEvent("event", true, true)
  return event.timeStamp
}

/// @internal
export function endComposition(view: EditorView, restarting = false) {
  if (browser.android && view.domObserver.flushingSoon >= 0) return
  view.domObserver.forceFlush()
  clearComposition(view)
  if (restarting || view.docView && view.docView.dirty) {
    let sel = selectionFromDOM(view)
    if (sel && !sel.eq(view.state.selection)) view.dispatch(view.state.tr.setSelection(sel))
    else if ((view.markCursor || restarting) && !view.state.selection.empty) view.dispatch(view.state.tr.deleteSelection())
    else view.updateState(view.state)
    return true
  }
  return false
}

function captureCopy(view: EditorView, dom: HTMLElement) {
  // The extra wrapper is somehow necessary on IE/Edge to prevent the
  // content from being mangled when it is put onto the clipboard
  if (!view.dom.parentNode) return
  let wrap = view.dom.parentNode.appendChild(document.createElement("div"))
  wrap.appendChild(dom)
  wrap.style.cssText = "position: fixed; left: -10000px; top: 10px"
  let sel = getSelection()!, range = document.createRange()
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

handlers.copy = editHandlers.cut = (view, _event) => {
  let event = _event as ClipboardEvent
  let sel = view.state.selection, cut = event.type == "cut"
  if (sel.empty) return

  // IE and Edge's clipboard interface is completely broken
  let data = brokenClipboardAPI ? null : event.clipboardData
  let slice = sel.content(), {dom, text} = serializeForClipboard(view, slice)
  if (data) {
    event.preventDefault()
    data.clearData()
    data.setData("text/html", dom.innerHTML)
    data.setData("text/plain", text)
  } else {
    captureCopy(view, dom)
  }
  if (cut) view.dispatch(view.state.tr.deleteSelection().scrollIntoView().setMeta("uiEvent", "cut"))
}

function sliceSingleNode(slice: Slice) {
  return slice.openStart == 0 && slice.openEnd == 0 && slice.content.childCount == 1 ? slice.content.firstChild : null
}

function capturePaste(view: EditorView, event: ClipboardEvent) {
  if (!view.dom.parentNode) return
  let plainText = view.input.shiftKey || view.state.selection.$from.parent.type.spec.code
  let target = view.dom.parentNode.appendChild(document.createElement(plainText ? "textarea" : "div"))
  if (!plainText) target.contentEditable = "true"
  target.style.cssText = "position: fixed; left: -10000px; top: 10px"
  target.focus()
  let plain = view.input.shiftKey && view.input.lastKeyCode != 45
  setTimeout(() => {
    view.focus()
    if (target.parentNode) target.parentNode.removeChild(target)
    if (plainText) doPaste(view, (target as HTMLTextAreaElement).value, null, plain, event)
    else doPaste(view, target.textContent!, target.innerHTML, plain, event)
  }, 50)
}

export function doPaste(view: EditorView, text: string, html: string | null, preferPlain: boolean, event: ClipboardEvent) {
  let slice = parseFromClipboard(view, text, html, preferPlain, view.state.selection.$from)
  if (view.someProp("handlePaste", f => f(view, event, slice || Slice.empty))) return true
  if (!slice) return false

  let singleNode = sliceSingleNode(slice)
  let tr = singleNode
    ? view.state.tr.replaceSelectionWith(singleNode, preferPlain)
    : view.state.tr.replaceSelection(slice)
  view.dispatch(tr.scrollIntoView().setMeta("paste", true).setMeta("uiEvent", "paste"))
  return true
}

function getText(clipboardData: DataTransfer) {
  let text = clipboardData.getData("text/plain") || clipboardData.getData("Text")
  if (text) return text
  let uris = clipboardData.getData("text/uri-list")
  return uris ? uris.replace(/\r?\n/g, " ") : ""
}

editHandlers.paste = (view, _event) => {
  let event = _event as ClipboardEvent
  // Handling paste from JavaScript during composition is very poorly
  // handled by browsers, so as a dodgy but preferable kludge, we just
  // let the browser do its native thing there, except on Android,
  // where the editor is almost always composing.
  if (view.composing && !browser.android) return
  let data = brokenClipboardAPI ? null : event.clipboardData
  let plain = view.input.shiftKey && view.input.lastKeyCode != 45
  if (data && doPaste(view, getText(data), data.getData("text/html"), plain, event))
    event.preventDefault()
  else
    capturePaste(view, event)
}

export class Dragging {
  constructor(readonly slice: Slice, readonly move: boolean, readonly node?: NodeSelection) {}
}

const dragCopyModifier: keyof DragEvent = browser.mac ? "altKey" : "ctrlKey"

handlers.dragstart = (view, _event) => {
  let event = _event as DragEvent
  let mouseDown = view.input.mouseDown
  if (mouseDown) mouseDown.done()
  if (!event.dataTransfer) return

  let sel = view.state.selection
  let pos = sel.empty ? null : view.posAtCoords(eventCoords(event))
  let node: undefined | NodeSelection
  if (pos && pos.pos >= sel.from && pos.pos <= (sel instanceof NodeSelection ? sel.to - 1: sel.to)) {
    // In selection
  } else if (mouseDown && mouseDown.mightDrag) {
    node = NodeSelection.create(view.state.doc, mouseDown.mightDrag.pos)
  } else if (event.target && (event.target as HTMLElement).nodeType == 1) {
    let desc = view.docView.nearestDesc(event.target as HTMLElement, true)
    if (desc && desc.node.type.spec.draggable && desc != view.docView)
      node = NodeSelection.create(view.state.doc, desc.posBefore)
  }
  let draggedSlice = (node || view.state.selection).content()
  let {dom, text, slice} = serializeForClipboard(view, draggedSlice)
  // Pre-120 Chrome versions clear files when calling `clearData` (#1472)
  if (!event.dataTransfer.files.length || !browser.chrome || browser.chrome_version > 120)
    event.dataTransfer.clearData()
  event.dataTransfer.setData(brokenClipboardAPI ? "Text" : "text/html", dom.innerHTML)
  // See https://github.com/ProseMirror/prosemirror/issues/1156
  event.dataTransfer.effectAllowed = "copyMove"
  if (!brokenClipboardAPI) event.dataTransfer.setData("text/plain", text)
  view.dragging = new Dragging(slice, !event[dragCopyModifier], node)
}

handlers.dragend = view => {
  let dragging = view.dragging
  window.setTimeout(() => {
    if (view.dragging == dragging)  view.dragging = null
  }, 50)
}

editHandlers.dragover = editHandlers.dragenter = (_, e) => e.preventDefault()

editHandlers.drop = (view, _event) => {
  let event = _event as DragEvent
  let dragging = view.dragging
  view.dragging = null

  if (!event.dataTransfer) return

  let eventPos = view.posAtCoords(eventCoords(event))
  if (!eventPos) return
  let $mouse = view.state.doc.resolve(eventPos.pos)
  let slice = dragging && dragging.slice
  if (slice) {
    view.someProp("transformPasted", f => { slice = f(slice!, view) })
  } else {
    slice = parseFromClipboard(view, getText(event.dataTransfer),
                               brokenClipboardAPI ? null : event.dataTransfer.getData("text/html"), false, $mouse)
  }
  let move = !!(dragging && !event[dragCopyModifier])
  if (view.someProp("handleDrop", f => f(view, event, slice || Slice.empty, move))) {
    event.preventDefault()
    return
  }
  if (!slice) return

  event.preventDefault()
  let insertPos = slice ? dropPoint(view.state.doc, $mouse.pos, slice) : $mouse.pos
  if (insertPos == null) insertPos = $mouse.pos

  let tr = view.state.tr
  if (move) {
    let {node} = dragging as Dragging
    if (node) node.replace(tr)
    else tr.deleteSelection()
  }

  let pos = tr.mapping.map(insertPos)
  let isNode = slice.openStart == 0 && slice.openEnd == 0 && slice.content.childCount == 1
  let beforeInsert = tr.doc
  if (isNode)
    tr.replaceRangeWith(pos, pos, slice.content.firstChild!)
  else
    tr.replaceRange(pos, pos, slice)
  if (tr.doc.eq(beforeInsert)) return

  let $pos = tr.doc.resolve(pos)
  if (isNode && NodeSelection.isSelectable(slice.content.firstChild!) &&
      $pos.nodeAfter && $pos.nodeAfter.sameMarkup(slice.content.firstChild!)) {
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
  view.input.lastFocus = Date.now()
  if (!view.focused) {
    view.domObserver.stop()
    view.dom.classList.add("ProseMirror-focused")
    view.domObserver.start()
    view.focused = true
    setTimeout(() => {
      if (view.docView && view.hasFocus() && !view.domObserver.currentSelection.eq(view.domSelectionRange()))
        selectionToDOM(view)
    }, 20)
  }
}

handlers.blur = (view, _event) => {
  let event = _event as FocusEvent
  if (view.focused) {
    view.domObserver.stop()
    view.dom.classList.remove("ProseMirror-focused")
    view.domObserver.start()
    if (event.relatedTarget && view.dom.contains(event.relatedTarget as HTMLElement))
      view.domObserver.currentSelection.clear()
    view.focused = false
  }
}

handlers.beforeinput = (view, _event: Event) => {
  let event = _event as InputEvent
  // We should probably do more with beforeinput events, but support
  // is so spotty that I'm still waiting to see where they are going.

  // Very specific hack to deal with backspace sometimes failing on
  // Chrome Android when after an uneditable node.
  if (browser.chrome && browser.android && event.inputType == "deleteContentBackward") {
    view.domObserver.flushSoon()
    let {domChangeCount} = view.input
    setTimeout(() => {
      if (view.input.domChangeCount != domChangeCount) return // Event already had some effect
      // This bug tends to close the virtual keyboard, so we refocus
      view.dom.blur()
      view.focus()
      if (view.someProp("handleKeyDown", f => f(view, keyEvent(8, "Backspace")))) return
      let {$cursor} = view.state.selection as TextSelection
      // Crude approximation of backspace behavior when no command handled it
      if ($cursor && $cursor.pos > 0) view.dispatch(view.state.tr.delete($cursor.pos - 1, $cursor.pos).scrollIntoView())
    }, 50)
  }
}

// Make sure all handlers get registered
for (let prop in editHandlers) handlers[prop] = editHandlers[prop]
