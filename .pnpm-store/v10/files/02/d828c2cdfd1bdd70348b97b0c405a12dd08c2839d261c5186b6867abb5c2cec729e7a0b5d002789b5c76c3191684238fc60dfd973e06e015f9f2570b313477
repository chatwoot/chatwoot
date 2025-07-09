import {Fragment, DOMParser, TagParseRule, Node, Mark, ResolvedPos} from "prosemirror-model"
import {Selection, TextSelection} from "prosemirror-state"

import {selectionBetween, selectionFromDOM, selectionToDOM} from "./selection"
import {selectionCollapsed, keyEvent, DOMNode} from "./dom"
import * as browser from "./browser"
import {EditorView} from "./index"

// Note that all referencing and parsing is done with the
// start-of-operation selection and document, since that's the one
// that the DOM represents. If any changes came in in the meantime,
// the modification is mapped over those before it is applied, in
// readDOMChange.

function parseBetween(view: EditorView, from_: number, to_: number) {
  let {node: parent, fromOffset, toOffset, from, to} = view.docView.parseRange(from_, to_)

  let domSel = view.domSelectionRange()
  let find: {node: DOMNode, offset: number, pos?: number}[] | undefined
  let anchor = domSel.anchorNode
  if (anchor && view.dom.contains(anchor.nodeType == 1 ? anchor : anchor.parentNode)) {
    find = [{node: anchor, offset: domSel.anchorOffset}]
    if (!selectionCollapsed(domSel))
      find.push({node: domSel.focusNode!, offset: domSel.focusOffset})
  }
  // Work around issue in Chrome where backspacing sometimes replaces
  // the deleted content with a random BR node (issues #799, #831)
  if (browser.chrome && view.input.lastKeyCode === 8) {
    for (let off = toOffset; off > fromOffset; off--) {
      let node = parent.childNodes[off - 1], desc = node.pmViewDesc
      if (node.nodeName == "BR" && !desc) { toOffset = off; break }
      if (!desc || desc.size) break
    }
  }
  let startDoc = view.state.doc
  let parser = view.someProp("domParser") || DOMParser.fromSchema(view.state.schema)
  let $from = startDoc.resolve(from)

  let sel = null, doc = parser.parse(parent, {
    topNode: $from.parent,
    topMatch: $from.parent.contentMatchAt($from.index()),
    topOpen: true,
    from: fromOffset,
    to: toOffset,
    preserveWhitespace: $from.parent.type.whitespace == "pre" ? "full" : true,
    findPositions: find,
    ruleFromNode,
    context: $from
  })
  if (find && find[0].pos != null) {
    let anchor = find[0].pos, head = find[1] && find[1].pos
    if (head == null) head = anchor
    sel = {anchor: anchor + from, head: head + from}
  }
  return {doc, sel, from, to}
}

function ruleFromNode(dom: DOMNode): Omit<TagParseRule, "tag"> | null {
  let desc = dom.pmViewDesc
  if (desc) {
    return desc.parseRule()
  } else if (dom.nodeName == "BR" && dom.parentNode) {
    // Safari replaces the list item or table cell with a BR
    // directly in the list node (?!) if you delete the last
    // character in a list item or table cell (#708, #862)
    if (browser.safari && /^(ul|ol)$/i.test(dom.parentNode.nodeName)) {
      let skip = document.createElement("div")
      skip.appendChild(document.createElement("li"))
      return {skip} as any
    } else if (dom.parentNode.lastChild == dom || browser.safari && /^(tr|table)$/i.test(dom.parentNode.nodeName)) {
      return {ignore: true}
    }
  } else if (dom.nodeName == "IMG" && (dom as HTMLElement).getAttribute("mark-placeholder")) {
    return {ignore: true}
  }
  return null
}

const isInline = /^(a|abbr|acronym|b|bd[io]|big|br|button|cite|code|data(list)?|del|dfn|em|i|ins|kbd|label|map|mark|meter|output|q|ruby|s|samp|small|span|strong|su[bp]|time|u|tt|var)$/i

export function readDOMChange(view: EditorView, from: number, to: number, typeOver: boolean, addedNodes: readonly DOMNode[]) {
  let compositionID = view.input.compositionPendingChanges || (view.composing ? view.input.compositionID : 0)
  view.input.compositionPendingChanges = 0
  
  if (from < 0) {
    let origin = view.input.lastSelectionTime > Date.now() - 50 ? view.input.lastSelectionOrigin : null
    let newSel = selectionFromDOM(view, origin)
    if (newSel && !view.state.selection.eq(newSel)) {
      if (browser.chrome && browser.android &&
          view.input.lastKeyCode === 13 && Date.now() - 100 < view.input.lastKeyCodeTime &&
          view.someProp("handleKeyDown", f => f(view, keyEvent(13, "Enter"))))
        return
      let tr = view.state.tr.setSelection(newSel)
      if (origin == "pointer") tr.setMeta("pointer", true)
      else if (origin == "key") tr.scrollIntoView()
      if (compositionID) tr.setMeta("composition", compositionID)
      view.dispatch(tr)
    }
    return
  }

  let $before = view.state.doc.resolve(from)
  let shared = $before.sharedDepth(to)
  from = $before.before(shared + 1)
  to = view.state.doc.resolve(to).after(shared + 1)

  let sel = view.state.selection
  let parse = parseBetween(view, from, to)

  let doc = view.state.doc, compare = doc.slice(parse.from, parse.to)
  let preferredPos, preferredSide: "start" | "end"
  // Prefer anchoring to end when Backspace is pressed
  if (view.input.lastKeyCode === 8 && Date.now() - 100 < view.input.lastKeyCodeTime) {
    preferredPos = view.state.selection.to
    preferredSide = "end"
  } else {
    preferredPos = view.state.selection.from
    preferredSide = "start"
  }
  view.input.lastKeyCode = null

  let change = findDiff(compare.content, parse.doc.content, parse.from, preferredPos, preferredSide)
  if (change) view.input.domChangeCount++
  if ((browser.ios && view.input.lastIOSEnter > Date.now() - 225 || browser.android) &&
      addedNodes.some(n => n.nodeType == 1 && !isInline.test(n.nodeName)) &&
      (!change || change.endA >= change.endB) &&
      view.someProp("handleKeyDown", f => f(view, keyEvent(13, "Enter")))) {
    view.input.lastIOSEnter = 0
    return
  }
  if (!change) {
    if (typeOver && sel instanceof TextSelection && !sel.empty && sel.$head.sameParent(sel.$anchor) &&
        !view.composing && !(parse.sel && parse.sel.anchor != parse.sel.head)) {
      change = {start: sel.from, endA: sel.to, endB: sel.to}
    } else {
      if (parse.sel) {
        let sel = resolveSelection(view, view.state.doc, parse.sel)
        if (sel && !sel.eq(view.state.selection)) {
          let tr = view.state.tr.setSelection(sel)
          if (compositionID) tr.setMeta("composition", compositionID)
          view.dispatch(tr)
        }
      }
      return
    }
  }

  // Handle the case where overwriting a selection by typing matches
  // the start or end of the selected content, creating a change
  // that's smaller than what was actually overwritten.
  if (view.state.selection.from < view.state.selection.to &&
      change.start == change.endB &&
      view.state.selection instanceof TextSelection) {
    if (change.start > view.state.selection.from && change.start <= view.state.selection.from + 2 &&
        view.state.selection.from >= parse.from) {
      change.start = view.state.selection.from
    } else if (change.endA < view.state.selection.to && change.endA >= view.state.selection.to - 2 &&
               view.state.selection.to <= parse.to) {
      change.endB += (view.state.selection.to - change.endA)
      change.endA = view.state.selection.to
    }
  }

  // IE11 will insert a non-breaking space _ahead_ of the space after
  // the cursor space when adding a space before another space. When
  // that happened, adjust the change to cover the space instead.
  if (browser.ie && browser.ie_version <= 11 && change.endB == change.start + 1 &&
      change.endA == change.start && change.start > parse.from &&
      parse.doc.textBetween(change.start - parse.from - 1, change.start - parse.from + 1) == " \u00a0") {
    change.start--
    change.endA--
    change.endB--
  }

  let $from = parse.doc.resolveNoCache(change.start - parse.from)
  let $to = parse.doc.resolveNoCache(change.endB - parse.from)
  let $fromA = doc.resolve(change.start)
  let inlineChange = $from.sameParent($to) && $from.parent.inlineContent && $fromA.end() >= change.endA
  let nextSel
  // If this looks like the effect of pressing Enter (or was recorded
  // as being an iOS enter press), just dispatch an Enter key instead.
  if (((browser.ios && view.input.lastIOSEnter > Date.now() - 225 &&
        (!inlineChange || addedNodes.some(n => n.nodeName == "DIV" || n.nodeName == "P"))) ||
       (!inlineChange && $from.pos < parse.doc.content.size && !$from.sameParent($to) &&
        (nextSel = Selection.findFrom(parse.doc.resolve($from.pos + 1), 1, true)) &&
        nextSel.head == $to.pos)) &&
      view.someProp("handleKeyDown", f => f(view, keyEvent(13, "Enter")))) {
    view.input.lastIOSEnter = 0
    return
  }
  // Same for backspace
  if (view.state.selection.anchor > change.start &&
      looksLikeBackspace(doc, change.start, change.endA, $from, $to) &&
      view.someProp("handleKeyDown", f => f(view, keyEvent(8, "Backspace")))) {
    if (browser.android && browser.chrome) view.domObserver.suppressSelectionUpdates() // #820
    return
  }

  // Chrome Android will occasionally, during composition, delete the
  // entire composition and then immediately insert it again. This is
  // used to detect that situation.
  if (browser.chrome && browser.android && change.endB == change.start)
    view.input.lastAndroidDelete = Date.now()

  // This tries to detect Android virtual keyboard
  // enter-and-pick-suggestion action. That sometimes (see issue
  // #1059) first fires a DOM mutation, before moving the selection to
  // the newly created block. And then, because ProseMirror cleans up
  // the DOM selection, it gives up moving the selection entirely,
  // leaving the cursor in the wrong place. When that happens, we drop
  // the new paragraph from the initial change, and fire a simulated
  // enter key afterwards.
  if (browser.android && !inlineChange && $from.start() != $to.start() && $to.parentOffset == 0 && $from.depth == $to.depth &&
      parse.sel && parse.sel.anchor == parse.sel.head && parse.sel.head == change.endA) {
    change.endB -= 2
    $to = parse.doc.resolveNoCache(change.endB - parse.from)
    setTimeout(() => {
      view.someProp("handleKeyDown", function (f) { return f(view, keyEvent(13, "Enter")); })
    }, 20)
  }

  let chFrom = change.start, chTo = change.endA

  let tr, storedMarks, markChange
  if (inlineChange) {
    if ($from.pos == $to.pos) { // Deletion
      // IE11 sometimes weirdly moves the DOM selection around after
      // backspacing out the first element in a textblock
      if (browser.ie && browser.ie_version <= 11 && $from.parentOffset == 0) {
        view.domObserver.suppressSelectionUpdates()
        setTimeout(() => selectionToDOM(view), 20)
      }
      tr = view.state.tr.delete(chFrom, chTo)
      storedMarks = doc.resolve(change.start).marksAcross(doc.resolve(change.endA))
    } else if ( // Adding or removing a mark
      change.endA == change.endB &&
      (markChange = isMarkChange($from.parent.content.cut($from.parentOffset, $to.parentOffset),
                                 $fromA.parent.content.cut($fromA.parentOffset, change.endA - $fromA.start())))
    ) {
      tr = view.state.tr
      if (markChange.type == "add") tr.addMark(chFrom, chTo, markChange.mark)
      else tr.removeMark(chFrom, chTo, markChange.mark)
    } else if ($from.parent.child($from.index()).isText && $from.index() == $to.index() - ($to.textOffset ? 0 : 1)) {
      // Both positions in the same text node -- simply insert text
      let text = $from.parent.textBetween($from.parentOffset, $to.parentOffset)
      if (view.someProp("handleTextInput", f => f(view, chFrom, chTo, text))) return
      tr = view.state.tr.insertText(text, chFrom, chTo)
    }
  }

  if (!tr)
    tr = view.state.tr.replace(chFrom, chTo, parse.doc.slice(change.start - parse.from, change.endB - parse.from))
  if (parse.sel) {
    let sel = resolveSelection(view, tr.doc, parse.sel)
    // Chrome Android will sometimes, during composition, report the
    // selection in the wrong place. If it looks like that is
    // happening, don't update the selection.
    // Edge just doesn't move the cursor forward when you start typing
    // in an empty block or between br nodes.
    if (sel && !(browser.chrome && browser.android && view.composing && sel.empty &&
                 (change.start != change.endB || view.input.lastAndroidDelete < Date.now() - 100) &&
                 (sel.head == chFrom || sel.head == tr.mapping.map(chTo) - 1) ||
                 browser.ie && sel.empty && sel.head == chFrom))
      tr.setSelection(sel)
  }
  if (storedMarks) tr.ensureMarks(storedMarks)
  if (compositionID) tr.setMeta("composition", compositionID)
  view.dispatch(tr.scrollIntoView())
}

function resolveSelection(view: EditorView, doc: Node, parsedSel: {anchor: number, head: number}) {
  if (Math.max(parsedSel.anchor, parsedSel.head) > doc.content.size) return null
  return selectionBetween(view, doc.resolve(parsedSel.anchor), doc.resolve(parsedSel.head))
}

// Given two same-length, non-empty fragments of inline content,
// determine whether the first could be created from the second by
// removing or adding a single mark type.
function isMarkChange(cur: Fragment, prev: Fragment) {
  let curMarks = cur.firstChild!.marks, prevMarks = prev.firstChild!.marks
  let added = curMarks, removed = prevMarks, type, mark: Mark | undefined, update
  for (let i = 0; i < prevMarks.length; i++) added = prevMarks[i].removeFromSet(added)
  for (let i = 0; i < curMarks.length; i++) removed = curMarks[i].removeFromSet(removed)
  if (added.length == 1 && removed.length == 0) {
    mark = added[0]
    type = "add"
    update = (node: Node) => node.mark(mark!.addToSet(node.marks))
  } else if (added.length == 0 && removed.length == 1) {
    mark = removed[0]
    type = "remove"
    update = (node: Node) => node.mark(mark!.removeFromSet(node.marks))
  } else {
    return null
  }
  let updated = []
  for (let i = 0; i < prev.childCount; i++) updated.push(update(prev.child(i)))
  if (Fragment.from(updated).eq(cur)) return {mark, type}
}

function looksLikeBackspace(old: Node, start: number, end: number, $newStart: ResolvedPos, $newEnd: ResolvedPos) {
  if (// The content must have shrunk
      end - start <= $newEnd.pos - $newStart.pos ||
      // newEnd must point directly at or after the end of the block that newStart points into
      skipClosingAndOpening($newStart, true, false) < $newEnd.pos)
    return false

  let $start = old.resolve(start)

  // Handle the case where, rather than joining blocks, the change just removed an entire block
  if (!$newStart.parent.isTextblock) {
    let after = $start.nodeAfter
    return after != null && end == start + after.nodeSize
  }

  // Start must be at the end of a block
  if ($start.parentOffset < $start.parent.content.size || !$start.parent.isTextblock)
    return false
  let $next = old.resolve(skipClosingAndOpening($start, true, true))
  // The next textblock must start before end and end near it
  if (!$next.parent.isTextblock || $next.pos > end ||
      skipClosingAndOpening($next, true, false) < end)
    return false

  // The fragments after the join point must match
  return $newStart.parent.content.cut($newStart.parentOffset).eq($next.parent.content)
}

function skipClosingAndOpening($pos: ResolvedPos, fromEnd: boolean, mayOpen: boolean) {
  let depth = $pos.depth, end = fromEnd ? $pos.end() : $pos.pos
  while (depth > 0 && (fromEnd || $pos.indexAfter(depth) == $pos.node(depth).childCount)) {
    depth--
    end++
    fromEnd = false
  }
  if (mayOpen) {
    let next = $pos.node(depth).maybeChild($pos.indexAfter(depth))
    while (next && !next.isLeaf) {
      next = next.firstChild
      end++
    }
  }
  return end
}

function findDiff(a: Fragment, b: Fragment, pos: number, preferredPos: number, preferredSide: "start" | "end") {
  let start = a.findDiffStart(b, pos)
  if (start == null) return null
  let {a: endA, b: endB} = a.findDiffEnd(b, pos + a.size, pos + b.size)!
  if (preferredSide == "end") {
    let adjust = Math.max(0, start - Math.min(endA, endB))
    preferredPos -= endA + adjust - start
  }
  if (endA < start && a.size < b.size) {
    let move = preferredPos <= start && preferredPos >= endA ? start - preferredPos : 0
    start -= move
    if (start && start < b.size && isSurrogatePair(b.textBetween(start - 1, start + 1)))
      start += move ? 1 : -1
    endB = start + (endB - endA)
    endA = start
  } else if (endB < start) {
    let move = preferredPos <= start && preferredPos >= endB ? start - preferredPos : 0
    start -= move
    if (start && start < a.size && isSurrogatePair(a.textBetween(start - 1, start + 1)))
      start += move ? 1 : -1
    endA = start + (endA - endB)
    endB = start
  }
  return {start, endA, endB}
}

function isSurrogatePair(str: string) {
  if (str.length != 2) return false
  let a = str.charCodeAt(0), b = str.charCodeAt(1)
  return a >= 0xDC00 && a <= 0xDFFF && b >= 0xD800 && b <= 0xDBFF
}
