import {TextSelection, NodeSelection} from "prosemirror-state"

import browser from "./browser"
import {selectionCollapsed, isEquivalentPosition, domIndex, isOnEdge} from "./dom"

export function selectionFromDOM(view, origin) {
  let domSel = view.root.getSelection(), doc = view.state.doc
  if (!domSel.focusNode) return null
  let nearestDesc = view.docView.nearestDesc(domSel.focusNode), inWidget = nearestDesc && nearestDesc.size == 0
  let head = view.docView.posFromDOM(domSel.focusNode, domSel.focusOffset)
  if (head < 0) return null
  let $head = doc.resolve(head), $anchor, selection
  if (selectionCollapsed(domSel)) {
    $anchor = $head
    while (nearestDesc && !nearestDesc.node) nearestDesc = nearestDesc.parent
    if (nearestDesc && nearestDesc.node.isAtom && NodeSelection.isSelectable(nearestDesc.node) && nearestDesc.parent
        && !(nearestDesc.node.isInline && isOnEdge(domSel.focusNode, domSel.focusOffset, nearestDesc.dom))) {
      let pos = nearestDesc.posBefore
      selection = new NodeSelection(head == pos ? $head : doc.resolve(pos))
    }
  } else {
    let anchor = view.docView.posFromDOM(domSel.anchorNode, domSel.anchorOffset)
    if (anchor < 0) return null
    $anchor = doc.resolve(anchor)
  }

  if (!selection) {
    let bias = origin == "pointer" || (view.state.selection.head < $head.pos && !inWidget) ? 1 : -1
    selection = selectionBetween(view, $anchor, $head, bias)
  }
  return selection
}

function editorOwnsSelection(view) {
  return view.editable ? view.hasFocus() :
    hasSelection(view) && document.activeElement && document.activeElement.contains(view.dom)
}

export function selectionToDOM(view, force) {
  let sel = view.state.selection
  syncNodeSelection(view, sel)

  if (!editorOwnsSelection(view)) return

  view.domObserver.disconnectSelection()

  if (view.cursorWrapper) {
    selectCursorWrapper(view)
  } else {
    let {anchor, head} = sel, resetEditableFrom, resetEditableTo
    if (brokenSelectBetweenUneditable && !(sel instanceof TextSelection)) {
      if (!sel.$from.parent.inlineContent)
        resetEditableFrom = temporarilyEditableNear(view, sel.from)
      if (!sel.empty && !sel.$from.parent.inlineContent)
        resetEditableTo = temporarilyEditableNear(view, sel.to)
    }
    view.docView.setSelection(anchor, head, view.root, force)
    if (brokenSelectBetweenUneditable) {
      if (resetEditableFrom) resetEditable(resetEditableFrom)
      if (resetEditableTo) resetEditable(resetEditableTo)
    }
    if (sel.visible) {
      view.dom.classList.remove("ProseMirror-hideselection")
    } else {
      view.dom.classList.add("ProseMirror-hideselection")
      if ("onselectionchange" in document) removeClassOnSelectionChange(view)
    }
  }

  view.domObserver.setCurSelection()
  view.domObserver.connectSelection()
}

// Kludge to work around Webkit not allowing a selection to start/end
// between non-editable block nodes. We briefly make something
// editable, set the selection, then set it uneditable again.

const brokenSelectBetweenUneditable = browser.safari || browser.chrome && browser.chrome_version < 63

function temporarilyEditableNear(view, pos) {
  let {node, offset} = view.docView.domFromPos(pos, 0)
  let after = offset < node.childNodes.length ? node.childNodes[offset] : null
  let before = offset ? node.childNodes[offset - 1] : null
  if (browser.safari && after && after.contentEditable == "false") return setEditable(after)
  if ((!after || after.contentEditable == "false") && (!before || before.contentEditable == "false")) {
    if (after) return setEditable(after)
    else if (before) return setEditable(before)
  }
}

function setEditable(element) {
  element.contentEditable = "true"
  if (browser.safari && element.draggable) { element.draggable = false; element.wasDraggable = true }
  return element
}

function resetEditable(element) {
  element.contentEditable = "false"
  if (element.wasDraggable) { element.draggable = true; element.wasDraggable = null }
}

function removeClassOnSelectionChange(view) {
  let doc = view.dom.ownerDocument
  doc.removeEventListener("selectionchange", view.hideSelectionGuard)
  let domSel = view.root.getSelection()
  let node = domSel.anchorNode, offset = domSel.anchorOffset
  doc.addEventListener("selectionchange", view.hideSelectionGuard = () => {
    if (domSel.anchorNode != node || domSel.anchorOffset != offset) {
      doc.removeEventListener("selectionchange", view.hideSelectionGuard)
      setTimeout(() => {
        if (!editorOwnsSelection(view) || view.state.selection.visible)
          view.dom.classList.remove("ProseMirror-hideselection")
      }, 20)
    }
  })
}

function selectCursorWrapper(view) {
  let domSel = view.root.getSelection(), range = document.createRange()
  let node = view.cursorWrapper.dom, img = node.nodeName == "IMG"
  if (img) range.setEnd(node.parentNode, domIndex(node) + 1)
  else range.setEnd(node, 0)
  range.collapse(false)
  domSel.removeAllRanges()
  domSel.addRange(range)
  // Kludge to kill 'control selection' in IE11 when selecting an
  // invisible cursor wrapper, since that would result in those weird
  // resize handles and a selection that considers the absolutely
  // positioned wrapper, rather than the root editable node, the
  // focused element.
  if (!img && !view.state.selection.visible && browser.ie && browser.ie_version <= 11) {
    node.disabled = true
    node.disabled = false
  }
}

export function syncNodeSelection(view, sel) {
  if (sel instanceof NodeSelection) {
    let desc = view.docView.descAt(sel.from)
    if (desc != view.lastSelectedViewDesc) {
      clearNodeSelection(view)
      if (desc) desc.selectNode()
      view.lastSelectedViewDesc = desc
    }
  } else {
    clearNodeSelection(view)
  }
}

// Clear all DOM statefulness of the last node selection.
function clearNodeSelection(view) {
  if (view.lastSelectedViewDesc) {
    if (view.lastSelectedViewDesc.parent)
      view.lastSelectedViewDesc.deselectNode()
    view.lastSelectedViewDesc = null
  }
}

export function selectionBetween(view, $anchor, $head, bias) {
  return view.someProp("createSelectionBetween", f => f(view, $anchor, $head))
    || TextSelection.between($anchor, $head, bias)
}

export function hasFocusAndSelection(view) {
  if (view.editable && view.root.activeElement != view.dom) return false
  return hasSelection(view)
}

export function hasSelection(view) {
  let sel = view.root.getSelection()
  if (!sel.anchorNode) return false
  try {
    // Firefox will raise 'permission denied' errors when accessing
    // properties of `sel.anchorNode` when it's in a generated CSS
    // element.
    return view.dom.contains(sel.anchorNode.nodeType == 3 ? sel.anchorNode.parentNode : sel.anchorNode) &&
      (view.editable || view.dom.contains(sel.focusNode.nodeType == 3 ? sel.focusNode.parentNode : sel.focusNode))
  } catch(_) {
    return false
  }
}

export function anchorInRightPlace(view) {
  let anchorDOM = view.docView.domFromPos(view.state.selection.anchor, 0)
  let domSel = view.root.getSelection()
  return isEquivalentPosition(anchorDOM.node, anchorDOM.offset, domSel.anchorNode, domSel.anchorOffset)
}
