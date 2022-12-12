import {nodeSize, textRange, parentNode} from "./dom"
import browser from "./browser"

function windowRect(doc) {
  return {left: 0, right: doc.documentElement.clientWidth,
          top: 0, bottom: doc.documentElement.clientHeight}
}

function getSide(value, side) {
  return typeof value == "number" ? value : value[side]
}

function clientRect(node) {
  let rect = node.getBoundingClientRect()
  // Adjust for elements with style "transform: scale()"
  let scaleX = (rect.width / node.offsetWidth) || 1
  let scaleY = (rect.height / node.offsetHeight) || 1
  // Make sure scrollbar width isn't included in the rectangle
  return {left: rect.left, right: rect.left + node.clientWidth * scaleX,
          top: rect.top, bottom: rect.top + node.clientHeight * scaleY}
}

export function scrollRectIntoView(view, rect, startDOM) {
  let scrollThreshold = view.someProp("scrollThreshold") || 0, scrollMargin = view.someProp("scrollMargin") || 5
  let doc = view.dom.ownerDocument
  for (let parent = startDOM || view.dom;; parent = parentNode(parent)) {
    if (!parent) break
    if (parent.nodeType != 1) continue
    let atTop = parent == doc.body || parent.nodeType != 1
    let bounding = atTop ? windowRect(doc) : clientRect(parent)
    let moveX = 0, moveY = 0
    if (rect.top < bounding.top + getSide(scrollThreshold, "top"))
      moveY = -(bounding.top - rect.top + getSide(scrollMargin, "top"))
    else if (rect.bottom > bounding.bottom - getSide(scrollThreshold, "bottom"))
      moveY = rect.bottom - bounding.bottom + getSide(scrollMargin, "bottom")
    if (rect.left < bounding.left + getSide(scrollThreshold, "left"))
      moveX = -(bounding.left - rect.left + getSide(scrollMargin, "left"))
    else if (rect.right > bounding.right - getSide(scrollThreshold, "right"))
      moveX = rect.right - bounding.right + getSide(scrollMargin, "right")
    if (moveX || moveY) {
      if (atTop) {
        doc.defaultView.scrollBy(moveX, moveY)
      } else {
        let startX = parent.scrollLeft, startY = parent.scrollTop
        if (moveY) parent.scrollTop += moveY
        if (moveX) parent.scrollLeft += moveX
        let dX = parent.scrollLeft - startX, dY = parent.scrollTop - startY
        rect = {left: rect.left - dX, top: rect.top - dY, right: rect.right - dX, bottom: rect.bottom - dY}
      }
    }
    if (atTop) break
  }
}

// Store the scroll position of the editor's parent nodes, along with
// the top position of an element near the top of the editor, which
// will be used to make sure the visible viewport remains stable even
// when the size of the content above changes.
export function storeScrollPos(view) {
  let rect = view.dom.getBoundingClientRect(), startY = Math.max(0, rect.top)
  let refDOM, refTop
  for (let x = (rect.left + rect.right) / 2, y = startY + 1;
       y < Math.min(innerHeight, rect.bottom); y += 5) {
    let dom = view.root.elementFromPoint(x, y)
    if (dom == view.dom || !view.dom.contains(dom)) continue
    let localRect = dom.getBoundingClientRect()
    if (localRect.top >= startY - 20) {
      refDOM = dom
      refTop = localRect.top
      break
    }
  }
  return {refDOM, refTop, stack: scrollStack(view.dom)}
}

function scrollStack(dom) {
  let stack = [], doc = dom.ownerDocument
  for (; dom; dom = parentNode(dom)) {
    stack.push({dom, top: dom.scrollTop, left: dom.scrollLeft})
    if (dom == doc) break
  }
  return stack
}

// Reset the scroll position of the editor's parent nodes to that what
// it was before, when storeScrollPos was called.
export function resetScrollPos({refDOM, refTop, stack}) {
  let newRefTop = refDOM ? refDOM.getBoundingClientRect().top : 0
  restoreScrollStack(stack, newRefTop == 0 ? 0 : newRefTop - refTop)
}

function restoreScrollStack(stack, dTop) {
  for (let i = 0; i < stack.length; i++) {
    let {dom, top, left} = stack[i]
    if (dom.scrollTop != top + dTop) dom.scrollTop = top + dTop
    if (dom.scrollLeft != left) dom.scrollLeft = left
  }
}

let preventScrollSupported = null
// Feature-detects support for .focus({preventScroll: true}), and uses
// a fallback kludge when not supported.
export function focusPreventScroll(dom) {
  if (dom.setActive) return dom.setActive() // in IE
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

function findOffsetInNode(node, coords) {
  let closest, dxClosest = 2e8, coordsClosest, offset = 0
  let rowBot = coords.top, rowTop = coords.top
  for (let child = node.firstChild, childIndex = 0; child; child = child.nextSibling, childIndex++) {
    let rects
    if (child.nodeType == 1) rects = child.getClientRects()
    else if (child.nodeType == 3) rects = textRange(child).getClientRects()
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
          coordsClosest = dx && closest.nodeType == 3 ? {left: rect.right < coords.left ? rect.right : rect.left, top: coords.top} : coords
          if (child.nodeType == 1 && dx)
            offset = childIndex + (coords.left >= (rect.left + rect.right) / 2 ? 1 : 0)
          continue
        }
      }
      if (!closest && (coords.left >= rect.right && coords.top >= rect.top ||
                       coords.left >= rect.left && coords.top >= rect.bottom))
        offset = childIndex + 1
    }
  }
  if (closest && closest.nodeType == 3) return findOffsetInText(closest, coordsClosest)
  if (!closest || (dxClosest && closest.nodeType == 1)) return {node, offset}
  return findOffsetInNode(closest, coordsClosest)
}

function findOffsetInText(node, coords) {
  let len = node.nodeValue.length
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

function inRect(coords, rect) {
  return coords.left >= rect.left - 1 && coords.left <= rect.right + 1&&
    coords.top >= rect.top - 1 && coords.top <= rect.bottom + 1
}

function targetKludge(dom, coords) {
  let parent = dom.parentNode
  if (parent && /^li$/i.test(parent.nodeName) && coords.left < dom.getBoundingClientRect().left)
    return parent
  return dom
}

function posFromElement(view, elt, coords) {
  let {node, offset} = findOffsetInNode(elt, coords), bias = -1
  if (node.nodeType == 1 && !node.firstChild) {
    let rect = node.getBoundingClientRect()
    bias = rect.left != rect.right && coords.left > (rect.left + rect.right) / 2 ? 1 : -1
  }
  return view.docView.posFromDOM(node, offset, bias)
}

function posFromCaret(view, node, offset, coords) {
  // Browser (in caretPosition/RangeFromPoint) will agressively
  // normalize towards nearby inline nodes. Since we are interested in
  // positions between block nodes too, we first walk up the hierarchy
  // of nodes to see if there are block nodes that the coordinates
  // fall outside of. If so, we take the position before/after that
  // block. If not, we call `posFromDOM` on the raw node/offset.
  let outside = -1
  for (let cur = node;;) {
    if (cur == view.dom) break
    let desc = view.docView.nearestDesc(cur, true)
    if (!desc) return null
    if (desc.node.isBlock && desc.parent) {
      let rect = desc.dom.getBoundingClientRect()
      if (rect.left > coords.left || rect.top > coords.top) outside = desc.posBefore
      else if (rect.right < coords.left || rect.bottom < coords.top) outside = desc.posAfter
      else break
    }
    cur = desc.dom.parentNode
  }
  return outside > -1 ? outside : view.docView.posFromDOM(node, offset)
}

function elementFromPoint(element, coords, box) {
  let len = element.childNodes.length
  if (len && box.top < box.bottom) {
    for (let startI = Math.max(0, Math.min(len - 1, Math.floor(len * (coords.top - box.top) / (box.bottom - box.top)) - 2)), i = startI;;) {
      let child = element.childNodes[i]
      if (child.nodeType == 1) {
        let rects = child.getClientRects()
        for (let j = 0; j < rects.length; j++) {
          let rect = rects[j]
          if (inRect(coords, rect)) return elementFromPoint(child, coords, rect)
        }
      }
      if ((i = (i + 1) % len) == startI) break
    }
  }
  return element
}

// Given an x,y position on the editor, get the position in the document.
export function posAtCoords(view, coords) {
  let root = view.root, node, offset
  if (root.caretPositionFromPoint) {
    try { // Firefox throws for this call in hard-to-predict circumstances (#994)
      let pos = root.caretPositionFromPoint(coords.left, coords.top)
      if (pos) ({offsetNode: node, offset} = pos)
    } catch (_) {}
  }
  if (!node && root.caretRangeFromPoint) {
    let range = root.caretRangeFromPoint(coords.left, coords.top)
    if (range) ({startContainer: node, startOffset: offset} = range)
  }

  let elt = root.elementFromPoint(coords.left, coords.top + 1), pos
  if (!elt || !view.dom.contains(elt.nodeType != 1 ? elt.parentNode : elt)) {
    let box = view.dom.getBoundingClientRect()
    if (!inRect(coords, box)) return null
    elt = elementFromPoint(view.dom, coords, box)
    if (!elt) return null
  }
  // Safari's caretRangeFromPoint returns nonsense when on a draggable element
  if (browser.safari && elt.draggable) node = offset = null
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
        if (next.nodeName == "IMG" && (box = next.getBoundingClientRect()).right <= coords.left &&
            box.bottom > coords.top)
          offset++
      }
    }
    // Suspiciously specific kludge to work around caret*FromPoint
    // never returning a position at the end of the document
    if (node == view.dom && offset == node.childNodes.length - 1 && node.lastChild.nodeType == 1 &&
        coords.top > node.lastChild.getBoundingClientRect().bottom)
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

function singleRect(object, bias) {
  let rects = object.getClientRects()
  return !rects.length ? object.getBoundingClientRect() : rects[bias < 0 ? 0 : rects.length - 1]
}

const BIDI = /[\u0590-\u05f4\u0600-\u06ff\u0700-\u08ac]/

// : (EditorView, number, number) → {left: number, top: number, right: number, bottom: number}
// Given a position in the document model, get a bounding box of the
// character at that position, relative to the window.
export function coordsAtPos(view, pos, side) {
  let {node, offset} = view.docView.domFromPos(pos, side < 0 ? -1 : 1)

  let supportEmptyRange = browser.webkit || browser.gecko
  if (node.nodeType == 3) {
    // These browsers support querying empty text ranges. Prefer that in
    // bidi context or when at the end of a node.
    if (supportEmptyRange && (BIDI.test(node.nodeValue) || (side < 0 ? !offset : offset == node.nodeValue.length))) {
      let rect = singleRect(textRange(node, offset, offset), side)
      // Firefox returns bad results (the position before the space)
      // when querying a position directly after line-broken
      // whitespace. Detect this situation and and kludge around it
      if (browser.gecko && offset && /\s/.test(node.nodeValue[offset - 1]) && offset < node.nodeValue.length) {
        let rectBefore = singleRect(textRange(node, offset - 1, offset - 1), -1)
        if (rectBefore.top == rect.top) {
          let rectAfter = singleRect(textRange(node, offset, offset + 1), -1)
          if (rectAfter.top != rect.top)
            return flattenV(rectAfter, rectAfter.left < rectBefore.left)
        }
      }
      return rect
    } else {
      let from = offset, to = offset, takeSide = side < 0 ? 1 : -1
      if (side < 0 && !offset) { to++; takeSide = -1 }
      else if (side >= 0 && offset == node.nodeValue.length) { from--; takeSide = 1 }
      else if (side < 0) { from-- }
      else { to ++ }
      return flattenV(singleRect(textRange(node, from, to), takeSide), takeSide < 0)
    }
  }

  // Return a horizontal line in block context
  if (!view.state.doc.resolve(pos).parent.inlineContent) {
    if (offset && (side < 0 || offset == nodeSize(node))) {
      let before = node.childNodes[offset - 1]
      if (before.nodeType == 1) return flattenH(before.getBoundingClientRect(), false)
    }
    if (offset < nodeSize(node)) {
      let after = node.childNodes[offset]
      if (after.nodeType == 1) return flattenH(after.getBoundingClientRect(), true)
    }
    return flattenH(node.getBoundingClientRect(), side >= 0)
  }

  // Inline, not in text node (this is not Bidi-safe)
  if (offset && (side < 0 || offset == nodeSize(node))) {
    let before = node.childNodes[offset - 1]
    let target = before.nodeType == 3 ? textRange(before, nodeSize(before) - (supportEmptyRange ? 0 : 1))
        // BR nodes tend to only return the rectangle before them.
        // Only use them if they are the last element in their parent
        : before.nodeType == 1 && (before.nodeName != "BR" || !before.nextSibling) ? before : null
    if (target) return flattenV(singleRect(target, 1), false)
  }
  if (offset < nodeSize(node)) {
    let after = node.childNodes[offset]
    let target = after.nodeType == 3 ? textRange(after, 0, (supportEmptyRange ? 0 : 1))
        : after.nodeType == 1 ? after : null
    if (target) return flattenV(singleRect(target, -1), true)
  }
  // All else failed, just try to get a rectangle for the target node
  return flattenV(singleRect(node.nodeType == 3 ? textRange(node) : node, -side), side >= 0)
}

function flattenV(rect, left) {
  if (rect.width == 0) return rect
  let x = left ? rect.left : rect.right
  return {top: rect.top, bottom: rect.bottom, left: x, right: x}
}

function flattenH(rect, top) {
  if (rect.height == 0) return rect
  let y = top ? rect.top : rect.bottom
  return {top: y, bottom: y, left: rect.left, right: rect.right}
}

function withFlushedState(view, state, f) {
  let viewState = view.state, active = view.root.activeElement
  if (viewState != state) view.updateState(state)
  if (active != view.dom) view.focus()
  try {
    return f()
  } finally {
    if (viewState != state) view.updateState(viewState)
    if (active != view.dom && active) active.focus()
  }
}

// : (EditorView, number, number)
// Whether vertical position motion in a given direction
// from a position would leave a text block.
function endOfTextblockVertical(view, state, dir) {
  let sel = state.selection
  let $pos = dir == "up" ? sel.$from : sel.$to
  return withFlushedState(view, state, () => {
    let {node: dom} = view.docView.domFromPos($pos.pos, dir == "up" ? -1 : 1)
    for (;;) {
      let nearest = view.docView.nearestDesc(dom, true)
      if (!nearest) break
      if (nearest.node.isBlock) { dom = nearest.dom; break }
      dom = nearest.dom.parentNode
    }
    let coords = coordsAtPos(view, $pos.pos, 1)
    for (let child = dom.firstChild; child; child = child.nextSibling) {
      let boxes
      if (child.nodeType == 1) boxes = child.getClientRects()
      else if (child.nodeType == 3) boxes = textRange(child, 0, child.nodeValue.length).getClientRects()
      else continue
      for (let i = 0; i < boxes.length; i++) {
        let box = boxes[i]
        if (box.bottom > box.top && (dir == "up" ? box.bottom < coords.top + 1 : box.top > coords.bottom - 1))
          return false
      }
    }
    return true
  })
}

const maybeRTL = /[\u0590-\u08ac]/

function endOfTextblockHorizontal(view, state, dir) {
  let {$head} = state.selection
  if (!$head.parent.isTextblock) return false
  let offset = $head.parentOffset, atStart = !offset, atEnd = offset == $head.parent.content.size
  let sel = getSelection()
  // If the textblock is all LTR, or the browser doesn't support
  // Selection.modify (Edge), fall back to a primitive approach
  if (!maybeRTL.test($head.parent.textContent) || !sel.modify)
    return dir == "left" || dir == "backward" ? atStart : atEnd

  return withFlushedState(view, state, () => {
    // This is a huge hack, but appears to be the best we can
    // currently do: use `Selection.modify` to move the selection by
    // one character, and see if that moves the cursor out of the
    // textblock (or doesn't move it at all, when at the start/end of
    // the document).
    let oldRange = sel.getRangeAt(0), oldNode = sel.focusNode, oldOff = sel.focusOffset
    let oldBidiLevel = sel.caretBidiLevel // Only for Firefox
    sel.modify("move", dir, "character")
    let parentDOM = $head.depth ? view.docView.domAfterPos($head.before()) : view.dom
    let result = !parentDOM.contains(sel.focusNode.nodeType == 1 ? sel.focusNode : sel.focusNode.parentNode) ||
        (oldNode == sel.focusNode && oldOff == sel.focusOffset)
    // Restore the previous selection
    sel.removeAllRanges()
    sel.addRange(oldRange)
    if (oldBidiLevel != null) sel.caretBidiLevel = oldBidiLevel
    return result
  })
}

let cachedState = null, cachedDir = null, cachedResult = false
export function endOfTextblock(view, state, dir) {
  if (cachedState == state && cachedDir == dir) return cachedResult
  cachedState = state; cachedDir = dir
  return cachedResult = dir == "up" || dir == "down"
    ? endOfTextblockVertical(view, state, dir)
    : endOfTextblockHorizontal(view, state, dir)
}
