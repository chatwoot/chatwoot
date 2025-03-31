import {EditorState} from "prosemirror-state"
import {nodeSize, textRange, parentNode, caretFromPoint} from "./dom"
import * as browser from "./browser"
import {EditorView} from "./index"

export type Rect = {left: number, right: number, top: number, bottom: number}

function windowRect(doc: Document): Rect {
  let vp = doc.defaultView && doc.defaultView.visualViewport
  if (vp) return {
    left: 0, right: vp.width,
    top: 0, bottom: vp.height
  }
  return {left: 0, right: doc.documentElement.clientWidth,
          top: 0, bottom: doc.documentElement.clientHeight}
}

function getSide(value: number | Rect, side: keyof Rect): number {
  return typeof value == "number" ? value : value[side]
}

function clientRect(node: HTMLElement): Rect {
  let rect = node.getBoundingClientRect()
  // Adjust for elements with style "transform: scale()"
  let scaleX = (rect.width / node.offsetWidth) || 1
  let scaleY = (rect.height / node.offsetHeight) || 1
  // Make sure scrollbar width isn't included in the rectangle
  return {left: rect.left, right: rect.left + node.clientWidth * scaleX,
          top: rect.top, bottom: rect.top + node.clientHeight * scaleY}
}

export function scrollRectIntoView(view: EditorView, rect: Rect, startDOM: Node) {
  let scrollThreshold = view.someProp("scrollThreshold") || 0, scrollMargin = view.someProp("scrollMargin") || 5
  let doc = view.dom.ownerDocument
  for (let parent: Node | null = startDOM || view.dom;; parent = parentNode(parent)) {
    if (!parent) break
    if (parent.nodeType != 1) continue
    let elt = parent as HTMLElement
    let atTop = elt == doc.body
    let bounding = atTop ? windowRect(doc) : clientRect(elt as HTMLElement)
    let moveX = 0, moveY = 0
    if (rect.top < bounding.top + getSide(scrollThreshold, "top"))
      moveY = -(bounding.top - rect.top + getSide(scrollMargin, "top"))
    else if (rect.bottom > bounding.bottom - getSide(scrollThreshold, "bottom"))
      moveY = rect.bottom - rect.top > bounding.bottom - bounding.top
        ? rect.top + getSide(scrollMargin, "top") - bounding.top
        : rect.bottom - bounding.bottom + getSide(scrollMargin, "bottom")
    if (rect.left < bounding.left + getSide(scrollThreshold, "left"))
      moveX = -(bounding.left - rect.left + getSide(scrollMargin, "left"))
    else if (rect.right > bounding.right - getSide(scrollThreshold, "right"))
      moveX = rect.right - bounding.right + getSide(scrollMargin, "right")
    if (moveX || moveY) {
      if (atTop) {
        doc.defaultView!.scrollBy(moveX, moveY)
      } else {
        let startX = elt.scrollLeft, startY = elt.scrollTop
        if (moveY) elt.scrollTop += moveY
        if (moveX) elt.scrollLeft += moveX
        let dX = elt.scrollLeft - startX, dY = elt.scrollTop - startY
        rect = {left: rect.left - dX, top: rect.top - dY, right: rect.right - dX, bottom: rect.bottom - dY}
      }
    }
    if (atTop || /^(fixed|sticky)$/.test(getComputedStyle(parent as HTMLElement).position)) break
  }
}

// Store the scroll position of the editor's parent nodes, along with
// the top position of an element near the top of the editor, which
// will be used to make sure the visible viewport remains stable even
// when the size of the content above changes.
export function storeScrollPos(view: EditorView): {
  refDOM: HTMLElement,
  refTop: number,
  stack: {dom: HTMLElement, top: number, left: number}[]
} {
  let rect = view.dom.getBoundingClientRect(), startY = Math.max(0, rect.top)
  let refDOM: HTMLElement, refTop: number
  for (let x = (rect.left + rect.right) / 2, y = startY + 1;
       y < Math.min(innerHeight, rect.bottom); y += 5) {
    let dom = view.root.elementFromPoint(x, y)
    if (!dom || dom == view.dom || !view.dom.contains(dom)) continue
    let localRect = (dom as HTMLElement).getBoundingClientRect()
    if (localRect.top >= startY - 20) {
      refDOM = dom as HTMLElement
      refTop = localRect.top
      break
    }
  }
  return {refDOM: refDOM!, refTop: refTop!, stack: scrollStack(view.dom)}
}

function scrollStack(dom: Node): {dom: HTMLElement, top: number, left: number}[] {
  let stack = [], doc = dom.ownerDocument
  for (let cur: Node | null = dom; cur; cur = parentNode(cur)) {
    stack.push({dom: cur as HTMLElement, top: (cur as HTMLElement).scrollTop, left: (cur as HTMLElement).scrollLeft})
    if (dom == doc) break
  }
  return stack
}

// Reset the scroll position of the editor's parent nodes to that what
// it was before, when storeScrollPos was called.
export function resetScrollPos({refDOM, refTop, stack}: {
  refDOM: HTMLElement,
  refTop: number,
  stack: {dom: HTMLElement, top: number, left: number}[]
}) {
  let newRefTop = refDOM ? refDOM.getBoundingClientRect().top : 0
  restoreScrollStack(stack, newRefTop == 0 ? 0 : newRefTop - refTop)
}

function restoreScrollStack(stack: {dom: HTMLElement, top: number, left: number}[], dTop: number) {
  for (let i = 0; i < stack.length; i++) {
    let {dom, top, left} = stack[i]
    if (dom.scrollTop != top + dTop) dom.scrollTop = top + dTop
    if (dom.scrollLeft != left) dom.scrollLeft = left
  }
}

let preventScrollSupported: false | null | {preventScroll: boolean} = null
// Feature-detects support for .focus({preventScroll: true}), and uses
// a fallback kludge when not supported.
export function focusPreventScroll(dom: HTMLElement) {
  if ((dom as any).setActive) return (dom as any).setActive() // in IE
  if (preventScrollSupported) return dom.focus(preventScrollSupported)

  let stored = scrollStack(dom)
  dom.focus(preventScrollSupported == null ? {
    get preventScroll() {
      preventScrollSupported = {preventScroll: true}
      return true
    }
  } : undefined)
  if (!preventScrollSupported) {
    preventScrollSupported = false
    restoreScrollStack(stored, 0)
  }
}

function findOffsetInNode(node: HTMLElement, coords: {top: number, left: number}): {node: Node, offset: number} {
  let closest, dxClosest = 2e8, coordsClosest: {left: number, top: number} | undefined, offset = 0
  let rowBot = coords.top, rowTop = coords.top
  let firstBelow: Node | undefined, coordsBelow: {left: number, top: number} | undefined
  for (let child = node.firstChild, childIndex = 0; child; child = child.nextSibling, childIndex++) {
    let rects
    if (child.nodeType == 1) rects = (child as HTMLElement).getClientRects()
    else if (child.nodeType == 3) rects = textRange(child as Text).getClientRects()
    else continue

    for (let i = 0; i < rects.length; i++) {
      let rect = rects[i]
      if (rect.top <= rowBot && rect.bottom >= rowTop) {
        rowBot = Math.max(rect.bottom, rowBot)
        rowTop = Math.min(rect.top, rowTop)
        let dx = rect.left > coords.left ? rect.left - coords.left
            : rect.right < coords.left ? coords.left - rect.right : 0
        if (dx < dxClosest) {
          closest = child
          dxClosest = dx
          coordsClosest = dx && closest.nodeType == 3 ? {
            left: rect.right < coords.left ? rect.right : rect.left,
            top: coords.top
          } : coords
          if (child.nodeType == 1 && dx)
            offset = childIndex + (coords.left >= (rect.left + rect.right) / 2 ? 1 : 0)
          continue
        }
      } else if (rect.top > coords.top && !firstBelow && rect.left <= coords.left && rect.right >= coords.left) {
        firstBelow = child
        coordsBelow = {left: Math.max(rect.left, Math.min(rect.right, coords.left)), top: rect.top}
      }
      if (!closest && (coords.left >= rect.right && coords.top >= rect.top ||
                       coords.left >= rect.left && coords.top >= rect.bottom))
        offset = childIndex + 1
    }
  }
  if (!closest && firstBelow) { closest = firstBelow; coordsClosest = coordsBelow; dxClosest = 0 }
  if (closest && closest.nodeType == 3) return findOffsetInText(closest as Text, coordsClosest!)
  if (!closest || (dxClosest && closest.nodeType == 1)) return {node, offset}
  return findOffsetInNode(closest as HTMLElement, coordsClosest!)
}

function findOffsetInText(node: Text, coords: {top: number, left: number}) {
  let len = node.nodeValue!.length
  let range = document.createRange()
  for (let i = 0; i < len; i++) {
    range.setEnd(node, i + 1)
    range.setStart(node, i)
    let rect = singleRect(range, 1)
    if (rect.top == rect.bottom) continue
    if (inRect(coords, rect))
      return {node, offset: i + (coords.left >= (rect.left + rect.right) / 2 ? 1 : 0)}
  }
  return {node, offset: 0}
}

function inRect(coords: {top: number, left: number}, rect: Rect) {
  return coords.left >= rect.left - 1 && coords.left <= rect.right + 1&&
    coords.top >= rect.top - 1 && coords.top <= rect.bottom + 1
}

function targetKludge(dom: HTMLElement, coords: {top: number, left: number}) {
  let parent = dom.parentNode
  if (parent && /^li$/i.test(parent.nodeName) && coords.left < dom.getBoundingClientRect().left)
    return parent as HTMLElement
  return dom
}

function posFromElement(view: EditorView, elt: HTMLElement, coords: {top: number, left: number}) {
  let {node, offset} = findOffsetInNode(elt, coords), bias = -1
  if (node.nodeType == 1 && !node.firstChild) {
    let rect = (node as HTMLElement).getBoundingClientRect()
    bias = rect.left != rect.right && coords.left > (rect.left + rect.right) / 2 ? 1 : -1
  }
  return view.docView.posFromDOM(node, offset, bias)
}

function posFromCaret(view: EditorView, node: Node, offset: number, coords: {top: number, left: number}) {
  // Browser (in caretPosition/RangeFromPoint) will agressively
  // normalize towards nearby inline nodes. Since we are interested in
  // positions between block nodes too, we first walk up the hierarchy
  // of nodes to see if there are block nodes that the coordinates
  // fall outside of. If so, we take the position before/after that
  // block. If not, we call `posFromDOM` on the raw node/offset.
  let outsideBlock = -1
  for (let cur = node, sawBlock = false;;) {
    if (cur == view.dom) break
    let desc = view.docView.nearestDesc(cur, true)
    if (!desc) return null
    if (desc.dom.nodeType == 1 && (desc.node.isBlock && desc.parent || !desc.contentDOM)) {
      let rect = (desc.dom as HTMLElement).getBoundingClientRect()
      if (desc.node.isBlock && desc.parent) {
        // Only apply the horizontal test to the innermost block. Vertical for any parent.
        if (!sawBlock && rect.left > coords.left || rect.top > coords.top) outsideBlock = desc.posBefore
        else if (!sawBlock && rect.right < coords.left || rect.bottom < coords.top) outsideBlock = desc.posAfter
        sawBlock = true
      }
      if (!desc.contentDOM && outsideBlock < 0 && !desc.node.isText) {
        // If we are inside a leaf, return the side of the leaf closer to the coords
        let before = desc.node.isBlock ? coords.top < (rect.top + rect.bottom) / 2
          : coords.left < (rect.left + rect.right) / 2
        return before ? desc.posBefore : desc.posAfter
      }
    }
    cur = desc.dom.parentNode!
  }
  return outsideBlock > -1 ? outsideBlock : view.docView.posFromDOM(node, offset, -1)
}

function elementFromPoint(element: HTMLElement, coords: {top: number, left: number}, box: Rect): HTMLElement {
  let len = element.childNodes.length
  if (len && box.top < box.bottom) {
    for (let startI = Math.max(0, Math.min(len - 1, Math.floor(len * (coords.top - box.top) / (box.bottom - box.top)) - 2)), i = startI;;) {
      let child = element.childNodes[i]
      if (child.nodeType == 1) {
        let rects = (child as HTMLElement).getClientRects()
        for (let j = 0; j < rects.length; j++) {
          let rect = rects[j]
          if (inRect(coords, rect)) return elementFromPoint(child as HTMLElement, coords, rect)
        }
      }
      if ((i = (i + 1) % len) == startI) break
    }
  }
  return element
}

// Given an x,y position on the editor, get the position in the document.
export function posAtCoords(view: EditorView, coords: {top: number, left: number}) {
  let doc = view.dom.ownerDocument, node: Node | undefined, offset = 0
  let caret = caretFromPoint(doc, coords.left, coords.top)
  if (caret) ({node, offset} = caret)

  let elt = ((view.root as any).elementFromPoint ? view.root : doc)
              .elementFromPoint(coords.left, coords.top) as HTMLElement
  let pos
  if (!elt || !view.dom.contains(elt.nodeType != 1 ? elt.parentNode : elt)) {
    let box = view.dom.getBoundingClientRect()
    if (!inRect(coords, box)) return null
    elt = elementFromPoint(view.dom, coords, box)
    if (!elt) return null
  }
  // Safari's caretRangeFromPoint returns nonsense when on a draggable element
  if (browser.safari) {
    for (let p: Node | null = elt; node && p; p = parentNode(p))
      if ((p as HTMLElement).draggable) node = undefined
  }
  elt = targetKludge(elt, coords)
  if (node) {
    if (browser.gecko && node.nodeType == 1) {
      // Firefox will sometimes return offsets into <input> nodes, which
      // have no actual children, from caretPositionFromPoint (#953)
      offset = Math.min(offset, node.childNodes.length)
      // It'll also move the returned position before image nodes,
      // even if those are behind it.
      if (offset < node.childNodes.length) {
        let next = node.childNodes[offset], box
        if (next.nodeName == "IMG" && (box = (next as HTMLElement).getBoundingClientRect()).right <= coords.left &&
            box.bottom > coords.top)
          offset++
      }
    }
    let prev
    // When clicking above the right side of an uneditable node, Chrome will report a cursor position after that node.
    if (browser.webkit && offset && node.nodeType == 1 && (prev = node.childNodes[offset - 1]).nodeType == 1 &&
        (prev as HTMLElement).contentEditable == "false" && (prev as HTMLElement).getBoundingClientRect().top >= coords.top)
      offset--
    // Suspiciously specific kludge to work around caret*FromPoint
    // never returning a position at the end of the document
    if (node == view.dom && offset == node.childNodes.length - 1 && node.lastChild!.nodeType == 1 &&
        coords.top > (node.lastChild as HTMLElement).getBoundingClientRect().bottom)
      pos = view.state.doc.content.size
    // Ignore positions directly after a BR, since caret*FromPoint
    // 'round up' positions that would be more accurately placed
    // before the BR node.
    else if (offset == 0 || node.nodeType != 1 || node.childNodes[offset - 1].nodeName != "BR")
      pos = posFromCaret(view, node, offset, coords)
  }
  if (pos == null) pos = posFromElement(view, elt, coords)

  let desc = view.docView.nearestDesc(elt, true)
  return {pos, inside: desc ? desc.posAtStart - desc.border : -1}
}

function nonZero(rect: DOMRect) {
  return rect.top < rect.bottom || rect.left < rect.right
}

function singleRect(target: HTMLElement | Range, bias: number): DOMRect {
  let rects = target.getClientRects()
  if (rects.length) {
    let first = rects[bias < 0 ? 0 : rects.length - 1]
    if (nonZero(first)) return first
  }
  return Array.prototype.find.call(rects, nonZero) || target.getBoundingClientRect()
}

const BIDI = /[\u0590-\u05f4\u0600-\u06ff\u0700-\u08ac]/

// Given a position in the document model, get a bounding box of the
// character at that position, relative to the window.
export function coordsAtPos(view: EditorView, pos: number, side: number): Rect {
  let {node, offset, atom} = view.docView.domFromPos(pos, side < 0 ? -1 : 1)

  let supportEmptyRange = browser.webkit || browser.gecko
  if (node.nodeType == 3) {
    // These browsers support querying empty text ranges. Prefer that in
    // bidi context or when at the end of a node.
    if (supportEmptyRange && (BIDI.test(node.nodeValue!) || (side < 0 ? !offset : offset == node.nodeValue!.length))) {
      let rect = singleRect(textRange(node as Text, offset, offset), side)
      // Firefox returns bad results (the position before the space)
      // when querying a position directly after line-broken
      // whitespace. Detect this situation and and kludge around it
      if (browser.gecko && offset && /\s/.test(node.nodeValue![offset - 1]) && offset < node.nodeValue!.length) {
        let rectBefore = singleRect(textRange(node as Text, offset - 1, offset - 1), -1)
        if (rectBefore.top == rect.top) {
          let rectAfter = singleRect(textRange(node as Text, offset, offset + 1), -1)
          if (rectAfter.top != rect.top)
            return flattenV(rectAfter, rectAfter.left < rectBefore.left)
        }
      }
      return rect
    } else {
      let from = offset, to = offset, takeSide = side < 0 ? 1 : -1
      if (side < 0 && !offset) { to++; takeSide = -1 }
      else if (side >= 0 && offset == node.nodeValue!.length) { from--; takeSide = 1 }
      else if (side < 0) { from-- }
      else { to ++ }
      return flattenV(singleRect(textRange(node as Text, from, to), takeSide), takeSide < 0)
    }
  }

  let $dom = view.state.doc.resolve(pos - (atom || 0))
  // Return a horizontal line in block context
  if (!$dom.parent.inlineContent) {
    if (atom == null && offset && (side < 0 || offset == nodeSize(node))) {
      let before = node.childNodes[offset - 1]
      if (before.nodeType == 1) return flattenH((before as HTMLElement).getBoundingClientRect(), false)
    }
    if (atom == null && offset < nodeSize(node)) {
      let after = node.childNodes[offset]
      if (after.nodeType == 1) return flattenH((after as HTMLElement).getBoundingClientRect(), true)
    }
    return flattenH((node as HTMLElement).getBoundingClientRect(), side >= 0)
  }

  // Inline, not in text node (this is not Bidi-safe)
  if (atom == null && offset && (side < 0 || offset == nodeSize(node))) {
    let before = node.childNodes[offset - 1]
    let target = before.nodeType == 3 ? textRange(before as Text, nodeSize(before) - (supportEmptyRange ? 0 : 1))
        // BR nodes tend to only return the rectangle before them.
        // Only use them if they are the last element in their parent
        : before.nodeType == 1 && (before.nodeName != "BR" || !before.nextSibling) ? before : null
    if (target) return flattenV(singleRect(target as Range | HTMLElement, 1), false)
  }
  if (atom == null && offset < nodeSize(node)) {
    let after = node.childNodes[offset]
    while (after.pmViewDesc && after.pmViewDesc.ignoreForCoords) after = after.nextSibling!
    let target = !after ? null : after.nodeType == 3 ? textRange(after as Text, 0, (supportEmptyRange ? 0 : 1))
        : after.nodeType == 1 ? after : null
    if (target) return flattenV(singleRect(target as Range | HTMLElement, -1), true)
  }
  // All else failed, just try to get a rectangle for the target node
  return flattenV(singleRect(node.nodeType == 3 ? textRange(node as Text) : node as HTMLElement, -side), side >= 0)
}

function flattenV(rect: DOMRect, left: boolean) {
  if (rect.width == 0) return rect
  let x = left ? rect.left : rect.right
  return {top: rect.top, bottom: rect.bottom, left: x, right: x}
}

function flattenH(rect: DOMRect, top: boolean) {
  if (rect.height == 0) return rect
  let y = top ? rect.top : rect.bottom
  return {top: y, bottom: y, left: rect.left, right: rect.right}
}

function withFlushedState<T>(view: EditorView, state: EditorState, f: () => T): T {
  let viewState = view.state, active = view.root.activeElement as HTMLElement
  if (viewState != state) view.updateState(state)
  if (active != view.dom) view.focus()
  try {
    return f()
  } finally {
    if (viewState != state) view.updateState(viewState)
    if (active != view.dom && active) active.focus()
  }
}

// Whether vertical position motion in a given direction
// from a position would leave a text block.
function endOfTextblockVertical(view: EditorView, state: EditorState, dir: "up" | "down") {
  let sel = state.selection
  let $pos = dir == "up" ? sel.$from : sel.$to
  return withFlushedState(view, state, () => {
    let {node: dom} = view.docView.domFromPos($pos.pos, dir == "up" ? -1 : 1)
    for (;;) {
      let nearest = view.docView.nearestDesc(dom, true)
      if (!nearest) break
      if (nearest.node.isBlock) { dom = nearest.contentDOM || nearest.dom; break }
      dom = nearest.dom.parentNode!
    }
    let coords = coordsAtPos(view, $pos.pos, 1)
    for (let child = dom.firstChild; child; child = child.nextSibling) {
      let boxes
      if (child.nodeType == 1) boxes = (child as HTMLElement).getClientRects()
      else if (child.nodeType == 3) boxes = textRange(child as Text, 0, child.nodeValue!.length).getClientRects()
      else continue
      for (let i = 0; i < boxes.length; i++) {
        let box = boxes[i]
        if (box.bottom > box.top + 1 &&
            (dir == "up" ? coords.top - box.top > (box.bottom - coords.top) * 2
             : box.bottom - coords.bottom > (coords.bottom - box.top) * 2))
          return false
      }
    }
    return true
  })
}

const maybeRTL = /[\u0590-\u08ac]/

function endOfTextblockHorizontal(view: EditorView, state: EditorState, dir: "left" | "right" | "forward" | "backward") {
  let {$head} = state.selection
  if (!$head.parent.isTextblock) return false
  let offset = $head.parentOffset, atStart = !offset, atEnd = offset == $head.parent.content.size
  let sel: Selection = view.domSelection()!
  if (!sel) return $head.pos == $head.start() || $head.pos == $head.end()
  // If the textblock is all LTR, or the browser doesn't support
  // Selection.modify (Edge), fall back to a primitive approach
  if (!maybeRTL.test($head.parent.textContent) || !(sel as any).modify)
    return dir == "left" || dir == "backward" ? atStart : atEnd

  return withFlushedState(view, state, () => {
    // This is a huge hack, but appears to be the best we can
    // currently do: use `Selection.modify` to move the selection by
    // one character, and see if that moves the cursor out of the
    // textblock (or doesn't move it at all, when at the start/end of
    // the document).
    let {focusNode: oldNode, focusOffset: oldOff, anchorNode, anchorOffset} = view.domSelectionRange()
    let oldBidiLevel = (sel as any).caretBidiLevel // Only for Firefox
    ;(sel as any).modify("move", dir, "character")
    let parentDOM = $head.depth ? view.docView.domAfterPos($head.before()) : view.dom
    let {focusNode: newNode, focusOffset: newOff} = view.domSelectionRange()
    let result = newNode && !parentDOM.contains(newNode.nodeType == 1 ? newNode : newNode.parentNode) ||
        (oldNode == newNode && oldOff == newOff)
    // Restore the previous selection
    try {
      sel.collapse(anchorNode, anchorOffset)
      if (oldNode && (oldNode != anchorNode || oldOff != anchorOffset) && sel.extend) sel.extend(oldNode, oldOff)
    } catch (_) {}
    if (oldBidiLevel != null) (sel as any).caretBidiLevel = oldBidiLevel
    return result
  })
}

export type TextblockDir = "up" | "down" | "left" | "right" | "forward" | "backward"

let cachedState: EditorState | null = null
let cachedDir: TextblockDir | null = null
let cachedResult: boolean = false
export function endOfTextblock(view: EditorView, state: EditorState, dir: TextblockDir) {
  if (cachedState == state && cachedDir == dir) return cachedResult
  cachedState = state; cachedDir = dir
  return cachedResult = dir == "up" || dir == "down"
    ? endOfTextblockVertical(view, state, dir)
    : endOfTextblockHorizontal(view, state, dir)
}
