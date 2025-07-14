export type DOMNode = InstanceType<typeof window.Node>
export type DOMSelection = InstanceType<typeof window.Selection>
export type DOMSelectionRange = {
  focusNode: DOMNode | null, focusOffset: number,
  anchorNode: DOMNode | null, anchorOffset: number
}

export const domIndex = function(node: Node) {
  for (var index = 0;; index++) {
    node = node.previousSibling!
    if (!node) return index
  }
}

export const parentNode = function(node: Node): Node | null {
  let parent = (node as HTMLSlotElement).assignedSlot || node.parentNode
  return parent && parent.nodeType == 11 ? (parent as ShadowRoot).host : parent
}

let reusedRange: Range | null = null

// Note that this will always return the same range, because DOM range
// objects are every expensive, and keep slowing down subsequent DOM
// updates, for some reason.
export const textRange = function(node: Text, from?: number, to?: number) {
  let range = reusedRange || (reusedRange = document.createRange())
  range.setEnd(node, to == null ? node.nodeValue!.length : to)
  range.setStart(node, from || 0)
  return range
}

export const clearReusedRange = function() {
  reusedRange = null;
}

// Scans forward and backward through DOM positions equivalent to the
// given one to see if the two are in the same place (i.e. after a
// text node vs at the end of that text node)
export const isEquivalentPosition = function(node: Node, off: number, targetNode: Node, targetOff: number) {
  return targetNode && (scanFor(node, off, targetNode, targetOff, -1) ||
                        scanFor(node, off, targetNode, targetOff, 1))
}

const atomElements = /^(img|br|input|textarea|hr)$/i

function scanFor(node: Node, off: number, targetNode: Node, targetOff: number, dir: number) {
  for (;;) {
    if (node == targetNode && off == targetOff) return true
    if (off == (dir < 0 ? 0 : nodeSize(node))) {
      let parent = node.parentNode
      if (!parent || parent.nodeType != 1 || hasBlockDesc(node) || atomElements.test(node.nodeName) ||
          (node as HTMLElement).contentEditable == "false")
        return false
      off = domIndex(node) + (dir < 0 ? 0 : 1)
      node = parent
    } else if (node.nodeType == 1) {
      node = node.childNodes[off + (dir < 0 ? -1 : 0)]
      if ((node as HTMLElement).contentEditable == "false") return false
      off = dir < 0 ? nodeSize(node) : 0
    } else {
      return false
    }
  }
}

export function nodeSize(node: Node) {
  return node.nodeType == 3 ? node.nodeValue!.length : node.childNodes.length
}

export function textNodeBefore(node: Node, offset: number) {
  for (;;) {
    if (node.nodeType == 3 && offset) return node as Text
    if (node.nodeType == 1 && offset > 0) {
      if ((node as HTMLElement).contentEditable == "false") return null
      node = node.childNodes[offset - 1]
      offset = nodeSize(node)
    } else if (node.parentNode && !hasBlockDesc(node)) {
      offset = domIndex(node)
      node = node.parentNode
    } else {
      return null
    }
  }
}

export function textNodeAfter(node: Node, offset: number) {
  for (;;) {
    if (node.nodeType == 3 && offset < node.nodeValue!.length) return node as Text
    if (node.nodeType == 1 && offset < node.childNodes.length) {
      if ((node as HTMLElement).contentEditable == "false") return null
      node = node.childNodes[offset]
      offset = 0
    } else if (node.parentNode && !hasBlockDesc(node)) {
      offset = domIndex(node) + 1
      node = node.parentNode
    } else {
      return null
    }
  }
}

export function isOnEdge(node: Node, offset: number, parent: Node) {
  for (let atStart = offset == 0, atEnd = offset == nodeSize(node); atStart || atEnd;) {
    if (node == parent) return true
    let index = domIndex(node)
    node = node.parentNode!
    if (!node) return false
    atStart = atStart && index == 0
    atEnd = atEnd && index == nodeSize(node)
  }
}

export function hasBlockDesc(dom: Node) {
  let desc
  for (let cur: Node | null = dom; cur; cur = cur.parentNode) if (desc = cur.pmViewDesc) break
  return desc && desc.node && desc.node.isBlock && (desc.dom == dom || desc.contentDOM == dom)
}

// Work around Chrome issue https://bugs.chromium.org/p/chromium/issues/detail?id=447523
// (isCollapsed inappropriately returns true in shadow dom)
export const selectionCollapsed = function(domSel: DOMSelectionRange) {
  return domSel.focusNode && isEquivalentPosition(domSel.focusNode, domSel.focusOffset,
                                                  domSel.anchorNode!, domSel.anchorOffset)
}

export function keyEvent(keyCode: number, key: string) {
  let event = document.createEvent("Event") as KeyboardEvent
  event.initEvent("keydown", true, true)
  ;(event as any).keyCode = keyCode
  ;(event as any).key = (event as any).code = key
  return event
}

export function deepActiveElement(doc: Document) {
  let elt = doc.activeElement
  while (elt && elt.shadowRoot) elt = elt.shadowRoot.activeElement
  return elt
}

export function caretFromPoint(doc: Document, x: number, y: number): {node: Node, offset: number} | undefined {
  if ((doc as any).caretPositionFromPoint) {
    try { // Firefox throws for this call in hard-to-predict circumstances (#994)
      let pos = (doc as any).caretPositionFromPoint(x, y)
      // Clip the offset, because Chrome will return a text offset
      // into <input> nodes, which can't be treated as a regular DOM
      // offset
      if (pos) return {node: pos.offsetNode, offset: Math.min(nodeSize(pos.offsetNode), pos.offset)}
    } catch (_) {}
  }
  if (doc.caretRangeFromPoint) {
    let range = doc.caretRangeFromPoint(x, y)
    if (range) return {node: range.startContainer, offset: Math.min(nodeSize(range.startContainer), range.startOffset)}
  }
}
