import {Selection, NodeSelection, TextSelection, AllSelection} from "prosemirror-state"
import browser from "./browser"
import {domIndex, selectionCollapsed} from "./dom"
import {selectionToDOM} from "./selection"

function moveSelectionBlock(state, dir) {
  let {$anchor, $head} = state.selection
  let $side = dir > 0 ? $anchor.max($head) : $anchor.min($head)
  let $start = !$side.parent.inlineContent ? $side : $side.depth ? state.doc.resolve(dir > 0 ? $side.after() : $side.before()) : null
  return $start && Selection.findFrom($start, dir)
}

function apply(view, sel) {
  view.dispatch(view.state.tr.setSelection(sel).scrollIntoView())
  return true
}

function selectHorizontally(view, dir, mods) {
  let sel = view.state.selection
  if (sel instanceof TextSelection) {
    if (!sel.empty || mods.indexOf("s") > -1) {
      return false
    } else if (view.endOfTextblock(dir > 0 ? "right" : "left")) {
      let next = moveSelectionBlock(view.state, dir)
      if (next && (next instanceof NodeSelection)) return apply(view, next)
      return false
    } else if (!(browser.mac && mods.indexOf("m") > -1)) {
      let $head = sel.$head, node = $head.textOffset ? null : dir < 0 ? $head.nodeBefore : $head.nodeAfter, desc
      if (!node || node.isText) return false
      let nodePos = dir < 0 ? $head.pos - node.nodeSize : $head.pos
      if (!(node.isAtom || (desc = view.docView.descAt(nodePos)) && !desc.contentDOM)) return false
      if (NodeSelection.isSelectable(node)) {
        return apply(view, new NodeSelection(dir < 0 ? view.state.doc.resolve($head.pos - node.nodeSize) : $head))
      } else if (browser.webkit) {
        // Chrome and Safari will introduce extra pointless cursor
        // positions around inline uneditable nodes, so we have to
        // take over and move the cursor past them (#937)
        return apply(view, new TextSelection(view.state.doc.resolve(dir < 0 ? nodePos : nodePos + node.nodeSize)))
      } else {
        return false
      }
    }
  } else if (sel instanceof NodeSelection && sel.node.isInline) {
    return apply(view, new TextSelection(dir > 0 ? sel.$to : sel.$from))
  } else {
    let next = moveSelectionBlock(view.state, dir)
    if (next) return apply(view, next)
    return false
  }
}

function nodeLen(node) {
  return node.nodeType == 3 ? node.nodeValue.length : node.childNodes.length
}

function isIgnorable(dom) {
  let desc = dom.pmViewDesc
  return desc && desc.size == 0 && (dom.nextSibling || dom.nodeName != "BR")
}

// Make sure the cursor isn't directly after one or more ignored
// nodes, which will confuse the browser's cursor motion logic.
function skipIgnoredNodesLeft(view) {
  let sel = view.root.getSelection()
  let node = sel.focusNode, offset = sel.focusOffset
  if (!node) return
  let moveNode, moveOffset, force = false
  // Gecko will do odd things when the selection is directly in front
  // of a non-editable node, so in that case, move it into the next
  // node if possible. Issue prosemirror/prosemirror#832.
  if (browser.gecko && node.nodeType == 1 && offset < nodeLen(node) && isIgnorable(node.childNodes[offset])) force = true
  for (;;) {
    if (offset > 0) {
      if (node.nodeType != 1) {
        break
      } else {
        let before = node.childNodes[offset - 1]
        if (isIgnorable(before)) {
          moveNode = node
          moveOffset = --offset
        } else if (before.nodeType == 3) {
          node = before
          offset = node.nodeValue.length
        } else break
      }
    } else if (isBlockNode(node)) {
      break
    } else {
      let prev = node.previousSibling
      while (prev && isIgnorable(prev)) {
        moveNode = node.parentNode
        moveOffset = domIndex(prev)
        prev = prev.previousSibling
      }
      if (!prev) {
        node = node.parentNode
        if (node == view.dom) break
        offset = 0
      } else {
        node = prev
        offset = nodeLen(node)
      }
    }
  }
  if (force) setSelFocus(view, sel, node, offset)
  else if (moveNode) setSelFocus(view, sel, moveNode, moveOffset)
}

// Make sure the cursor isn't directly before one or more ignored
// nodes.
function skipIgnoredNodesRight(view) {
  let sel = view.root.getSelection()
  let node = sel.focusNode, offset = sel.focusOffset
  if (!node) return
  let len = nodeLen(node)
  let moveNode, moveOffset
  for (;;) {
    if (offset < len) {
      if (node.nodeType != 1) break
      let after = node.childNodes[offset]
      if (isIgnorable(after)) {
        moveNode = node
        moveOffset = ++offset
      }
      else break
    } else if (isBlockNode(node)) {
      break
    } else {
      let next = node.nextSibling
      while (next && isIgnorable(next)) {
        moveNode = next.parentNode
        moveOffset = domIndex(next) + 1
        next = next.nextSibling
      }
      if (!next) {
        node = node.parentNode
        if (node == view.dom) break
        offset = len = 0
      } else {
        node = next
        offset = 0
        len = nodeLen(node)
      }
    }
  }
  if (moveNode) setSelFocus(view, sel, moveNode, moveOffset)
}

function isBlockNode(dom) {
  let desc = dom.pmViewDesc
  return desc && desc.node && desc.node.isBlock
}

function setSelFocus(view, sel, node, offset) {
  if (selectionCollapsed(sel)) {
    let range = document.createRange()
    range.setEnd(node, offset)
    range.setStart(node, offset)
    sel.removeAllRanges()
    sel.addRange(range)
  } else if (sel.extend) {
    sel.extend(node, offset)
  }
  view.domObserver.setCurSelection()
  let {state} = view
  // If no state update ends up happening, reset the selection.
  setTimeout(() => {
    if (view.state == state) selectionToDOM(view)
  }, 50)
}

// : (EditorState, number)
// Check whether vertical selection motion would involve node
// selections. If so, apply it (if not, the result is left to the
// browser)
function selectVertically(view, dir, mods) {
  let sel = view.state.selection
  if (sel instanceof TextSelection && !sel.empty || mods.indexOf("s") > -1) return false
  if (browser.mac && mods.indexOf("m") > -1) return false
  let {$from, $to} = sel

  if (!$from.parent.inlineContent || view.endOfTextblock(dir < 0 ? "up" : "down")) {
    let next = moveSelectionBlock(view.state, dir)
    if (next && (next instanceof NodeSelection))
      return apply(view, next)
  }
  if (!$from.parent.inlineContent) {
    let side = dir < 0 ? $from : $to
    let beyond = sel instanceof AllSelection ? Selection.near(side, dir) : Selection.findFrom(side, dir)
    return beyond ? apply(view, beyond) : false
  }
  return false
}

function stopNativeHorizontalDelete(view, dir) {
  if (!(view.state.selection instanceof TextSelection)) return true
  let {$head, $anchor, empty} = view.state.selection
  if (!$head.sameParent($anchor)) return true
  if (!empty) return false
  if (view.endOfTextblock(dir > 0 ? "forward" : "backward")) return true
  let nextNode = !$head.textOffset && (dir < 0 ? $head.nodeBefore : $head.nodeAfter)
  if (nextNode && !nextNode.isText) {
    let tr = view.state.tr
    if (dir < 0) tr.delete($head.pos - nextNode.nodeSize, $head.pos)
    else tr.delete($head.pos, $head.pos + nextNode.nodeSize)
    view.dispatch(tr)
    return true
  }
  return false
}

function switchEditable(view, node, state) {
  view.domObserver.stop()
  node.contentEditable = state
  view.domObserver.start()
}

// Issue #867 / #1090 / https://bugs.chromium.org/p/chromium/issues/detail?id=903821
// In which Safari (and at some point in the past, Chrome) does really
// wrong things when the down arrow is pressed when the cursor is
// directly at the start of a textblock and has an uneditable node
// after it
function safariDownArrowBug(view) {
  if (!browser.safari || view.state.selection.$head.parentOffset > 0) return
  let {focusNode, focusOffset} = view.root.getSelection()
  if (focusNode && focusNode.nodeType == 1 && focusOffset == 0 &&
      focusNode.firstChild && focusNode.firstChild.contentEditable == "false") {
    let child = focusNode.firstChild
    switchEditable(view, child, true)
    setTimeout(() => switchEditable(view, child, false), 20)
  }
}

// A backdrop key mapping used to make sure we always suppress keys
// that have a dangerous default effect, even if the commands they are
// bound to return false, and to make sure that cursor-motion keys
// find a cursor (as opposed to a node selection) when pressed. For
// cursor-motion keys, the code in the handlers also takes care of
// block selections.

function getMods(event) {
  let result = ""
  if (event.ctrlKey) result += "c"
  if (event.metaKey) result += "m"
  if (event.altKey) result += "a"
  if (event.shiftKey) result += "s"
  return result
}

export function captureKeyDown(view, event) {
  let code = event.keyCode, mods = getMods(event)
  if (code == 8 || (browser.mac && code == 72 && mods == "c")) { // Backspace, Ctrl-h on Mac
    return stopNativeHorizontalDelete(view, -1) || skipIgnoredNodesLeft(view)
  } else if (code == 46 || (browser.mac && code == 68 && mods == "c")) { // Delete, Ctrl-d on Mac
    return stopNativeHorizontalDelete(view, 1) || skipIgnoredNodesRight(view)
  } else if (code == 13 || code == 27) { // Enter, Esc
    return true
  } else if (code == 37) { // Left arrow
    return selectHorizontally(view, -1, mods) || skipIgnoredNodesLeft(view)
  } else if (code == 39) { // Right arrow
    return selectHorizontally(view, 1, mods) || skipIgnoredNodesRight(view)
  } else if (code == 38) { // Up arrow
    return selectVertically(view, -1, mods) || skipIgnoredNodesLeft(view)
  } else if (code == 40) { // Down arrow
    return safariDownArrowBug(view) || selectVertically(view, 1, mods) || skipIgnoredNodesRight(view)
  } else if (mods == (browser.mac ? "m" : "c") &&
             (code == 66 || code == 73 || code == 89 || code == 90)) { // Mod-[biyz]
    return true
  }
  return false
}
