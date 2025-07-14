import {Fragment, Slice, Node, ResolvedPos, NodeType, ContentMatch, Attrs} from "prosemirror-model"

import {Step} from "./step"
import {ReplaceStep, ReplaceAroundStep} from "./replace_step"
import {Transform} from "./transform"
import {insertPoint} from "./structure"

/// ‘Fit’ a slice into a given position in the document, producing a
/// [step](#transform.Step) that inserts it. Will return null if
/// there's no meaningful way to insert the slice here, or inserting it
/// would be a no-op (an empty slice over an empty range).
export function replaceStep(doc: Node, from: number, to = from, slice = Slice.empty): Step | null {
  if (from == to && !slice.size) return null

  let $from = doc.resolve(from), $to = doc.resolve(to)
  // Optimization -- avoid work if it's obvious that it's not needed.
  if (fitsTrivially($from, $to, slice)) return new ReplaceStep(from, to, slice)
  return new Fitter($from, $to, slice).fit()
}

function fitsTrivially($from: ResolvedPos, $to: ResolvedPos, slice: Slice) {
  return !slice.openStart && !slice.openEnd && $from.start() == $to.start() &&
    $from.parent.canReplace($from.index(), $to.index(), slice.content)
}

interface Fittable {
  sliceDepth: number
  frontierDepth: number
  parent: Node | null
  inject?: Fragment | null
  wrap?: readonly NodeType[]
}

// Algorithm for 'placing' the elements of a slice into a gap:
//
// We consider the content of each node that is open to the left to be
// independently placeable. I.e. in <p("foo"), p("bar")>, when the
// paragraph on the left is open, "foo" can be placed (somewhere on
// the left side of the replacement gap) independently from p("bar").
//
// This class tracks the state of the placement progress in the
// following properties:
//
//  - `frontier` holds a stack of `{type, match}` objects that
//    represent the open side of the replacement. It starts at
//    `$from`, then moves forward as content is placed, and is finally
//    reconciled with `$to`.
//
//  - `unplaced` is a slice that represents the content that hasn't
//    been placed yet.
//
//  - `placed` is a fragment of placed content. Its open-start value
//    is implicit in `$from`, and its open-end value in `frontier`.
class Fitter {
  frontier: {type: NodeType, match: ContentMatch}[] = []
  placed: Fragment = Fragment.empty

  constructor(
    readonly $from: ResolvedPos,
    readonly $to: ResolvedPos,
    public unplaced: Slice
  ) {
    for (let i = 0; i <= $from.depth; i++) {
      let node = $from.node(i)
      this.frontier.push({
        type: node.type,
        match: node.contentMatchAt($from.indexAfter(i))
      })
    }

    for (let i = $from.depth; i > 0; i--)
      this.placed = Fragment.from($from.node(i).copy(this.placed))
  }

  get depth() { return this.frontier.length - 1 }

  fit() {
    // As long as there's unplaced content, try to place some of it.
    // If that fails, either increase the open score of the unplaced
    // slice, or drop nodes from it, and then try again.
    while (this.unplaced.size) {
      let fit = this.findFittable()
      if (fit) this.placeNodes(fit)
      else this.openMore() || this.dropNode()
    }
    // When there's inline content directly after the frontier _and_
    // directly after `this.$to`, we must generate a `ReplaceAround`
    // step that pulls that content into the node after the frontier.
    // That means the fitting must be done to the end of the textblock
    // node after `this.$to`, not `this.$to` itself.
    let moveInline = this.mustMoveInline(), placedSize = this.placed.size - this.depth - this.$from.depth
    let $from = this.$from, $to = this.close(moveInline < 0 ? this.$to : $from.doc.resolve(moveInline))
    if (!$to) return null

    // If closing to `$to` succeeded, create a step
    let content = this.placed, openStart = $from.depth, openEnd = $to.depth
    while (openStart && openEnd && content.childCount == 1) { // Normalize by dropping open parent nodes
      content = content.firstChild!.content
      openStart--; openEnd--
    }
    let slice = new Slice(content, openStart, openEnd)
    if (moveInline > -1)
      return new ReplaceAroundStep($from.pos, moveInline, this.$to.pos, this.$to.end(), slice, placedSize)
    if (slice.size || $from.pos != this.$to.pos) // Don't generate no-op steps
      return new ReplaceStep($from.pos, $to.pos, slice)
    return null
  }

  // Find a position on the start spine of `this.unplaced` that has
  // content that can be moved somewhere on the frontier. Returns two
  // depths, one for the slice and one for the frontier.
  findFittable(): Fittable | undefined {
    let startDepth = this.unplaced.openStart
    for (let cur = this.unplaced.content, d = 0, openEnd = this.unplaced.openEnd; d < startDepth; d++) {
      let node = cur.firstChild!
      if (cur.childCount > 1) openEnd = 0
      if (node.type.spec.isolating && openEnd <= d) {
        startDepth = d
        break
      }
      cur = node.content
    }

    // Only try wrapping nodes (pass 2) after finding a place without
    // wrapping failed.
    for (let pass = 1; pass <= 2; pass++) {
      for (let sliceDepth = pass == 1 ? startDepth : this.unplaced.openStart; sliceDepth >= 0; sliceDepth--) {
        let fragment, parent = null
        if (sliceDepth) {
          parent = contentAt(this.unplaced.content, sliceDepth - 1).firstChild
          fragment = parent!.content
        } else {
          fragment = this.unplaced.content
        }
        let first = fragment.firstChild
        for (let frontierDepth = this.depth; frontierDepth >= 0; frontierDepth--) {
          let {type, match} = this.frontier[frontierDepth], wrap, inject: Fragment | null = null
          // In pass 1, if the next node matches, or there is no next
          // node but the parents look compatible, we've found a
          // place.
          if (pass == 1 && (first ? match.matchType(first.type) || (inject = match.fillBefore(Fragment.from(first), false))
                            : parent && type.compatibleContent(parent.type)))
            return {sliceDepth, frontierDepth, parent, inject}
          // In pass 2, look for a set of wrapping nodes that make
          // `first` fit here.
          else if (pass == 2 && first && (wrap = match.findWrapping(first.type)))
            return {sliceDepth, frontierDepth, parent, wrap}
          // Don't continue looking further up if the parent node
          // would fit here.
          if (parent && match.matchType(parent.type)) break
        }
      }
    }
  }

  openMore() {
    let {content, openStart, openEnd} = this.unplaced
    let inner = contentAt(content, openStart)
    if (!inner.childCount || inner.firstChild!.isLeaf) return false
    this.unplaced = new Slice(content, openStart + 1,
                              Math.max(openEnd, inner.size + openStart >= content.size - openEnd ? openStart + 1 : 0))
    return true
  }

  dropNode() {
    let {content, openStart, openEnd} = this.unplaced
    let inner = contentAt(content, openStart)
    if (inner.childCount <= 1 && openStart > 0) {
      let openAtEnd = content.size - openStart <= openStart + inner.size
      this.unplaced = new Slice(dropFromFragment(content, openStart - 1, 1), openStart - 1,
                                openAtEnd ? openStart - 1 : openEnd)
    } else {
      this.unplaced = new Slice(dropFromFragment(content, openStart, 1), openStart, openEnd)
    }
  }

  // Move content from the unplaced slice at `sliceDepth` to the
  // frontier node at `frontierDepth`. Close that frontier node when
  // applicable.
  placeNodes({sliceDepth, frontierDepth, parent, inject, wrap}: Fittable) {
    while (this.depth > frontierDepth) this.closeFrontierNode()
    if (wrap) for (let i = 0; i < wrap.length; i++) this.openFrontierNode(wrap[i])

    let slice = this.unplaced, fragment = parent ? parent.content : slice.content
    let openStart = slice.openStart - sliceDepth
    let taken = 0, add = []
    let {match, type} = this.frontier[frontierDepth]
    if (inject) {
      for (let i = 0; i < inject.childCount; i++) add.push(inject.child(i))
      match = match.matchFragment(inject)!
    }
    // Computes the amount of (end) open nodes at the end of the
    // fragment. When 0, the parent is open, but no more. When
    // negative, nothing is open.
    let openEndCount = (fragment.size + sliceDepth) - (slice.content.size - slice.openEnd)
    // Scan over the fragment, fitting as many child nodes as
    // possible.
    while (taken < fragment.childCount) {
      let next = fragment.child(taken), matches = match.matchType(next.type)
      if (!matches) break
      taken++
      if (taken > 1 || openStart == 0 || next.content.size) { // Drop empty open nodes
        match = matches
        add.push(closeNodeStart(next.mark(type.allowedMarks(next.marks)), taken == 1 ? openStart : 0,
                                taken == fragment.childCount ? openEndCount : -1))
      }
    }
    let toEnd = taken == fragment.childCount
    if (!toEnd) openEndCount = -1

    this.placed = addToFragment(this.placed, frontierDepth, Fragment.from(add))
    this.frontier[frontierDepth].match = match

    // If the parent types match, and the entire node was moved, and
    // it's not open, close this frontier node right away.
    if (toEnd && openEndCount < 0 && parent && parent.type == this.frontier[this.depth].type && this.frontier.length > 1)
      this.closeFrontierNode()

    // Add new frontier nodes for any open nodes at the end.
    for (let i = 0, cur = fragment; i < openEndCount; i++) {
      let node = cur.lastChild!
      this.frontier.push({type: node.type, match: node.contentMatchAt(node.childCount)})
      cur = node.content
    }

    // Update `this.unplaced`. Drop the entire node from which we
    // placed it we got to its end, otherwise just drop the placed
    // nodes.
    this.unplaced = !toEnd ? new Slice(dropFromFragment(slice.content, sliceDepth, taken), slice.openStart, slice.openEnd)
      : sliceDepth == 0 ? Slice.empty
      : new Slice(dropFromFragment(slice.content, sliceDepth - 1, 1),
                  sliceDepth - 1, openEndCount < 0 ? slice.openEnd : sliceDepth - 1)
  }

  mustMoveInline() {
    if (!this.$to.parent.isTextblock) return -1
    let top = this.frontier[this.depth], level
    if (!top.type.isTextblock || !contentAfterFits(this.$to, this.$to.depth, top.type, top.match, false) ||
        (this.$to.depth == this.depth && (level = this.findCloseLevel(this.$to)) && level.depth == this.depth)) return -1

    let {depth} = this.$to, after = this.$to.after(depth)
    while (depth > 1 && after == this.$to.end(--depth)) ++after
    return after
  }

  findCloseLevel($to: ResolvedPos) {
    scan: for (let i = Math.min(this.depth, $to.depth); i >= 0; i--) {
      let {match, type} = this.frontier[i]
      let dropInner = i < $to.depth && $to.end(i + 1) == $to.pos + ($to.depth - (i + 1))
      let fit = contentAfterFits($to, i, type, match, dropInner)
      if (!fit) continue
      for (let d = i - 1; d >= 0; d--) {
        let {match, type} = this.frontier[d]
        let matches = contentAfterFits($to, d, type, match, true)
        if (!matches || matches.childCount) continue scan
      }
      return {depth: i, fit, move: dropInner ? $to.doc.resolve($to.after(i + 1)) : $to}
    }
  }

  close($to: ResolvedPos) {
    let close = this.findCloseLevel($to)
    if (!close) return null

    while (this.depth > close.depth) this.closeFrontierNode()
    if (close.fit.childCount) this.placed = addToFragment(this.placed, close.depth, close.fit)
    $to = close.move
    for (let d = close.depth + 1; d <= $to.depth; d++) {
      let node = $to.node(d), add = node.type.contentMatch.fillBefore(node.content, true, $to.index(d))!
      this.openFrontierNode(node.type, node.attrs, add)
    }
    return $to
  }

  openFrontierNode(type: NodeType, attrs: Attrs | null = null, content?: Fragment) {
    let top = this.frontier[this.depth]
    top.match = top.match.matchType(type)!
    this.placed = addToFragment(this.placed, this.depth, Fragment.from(type.create(attrs, content)))
    this.frontier.push({type, match: type.contentMatch})
  }

  closeFrontierNode() {
    let open = this.frontier.pop()!
    let add = open.match.fillBefore(Fragment.empty, true)!
    if (add.childCount) this.placed = addToFragment(this.placed, this.frontier.length, add)
  }
}

function dropFromFragment(fragment: Fragment, depth: number, count: number): Fragment {
  if (depth == 0) return fragment.cutByIndex(count, fragment.childCount)
  return fragment.replaceChild(0, fragment.firstChild!.copy(dropFromFragment(fragment.firstChild!.content, depth - 1, count)))
}

function addToFragment(fragment: Fragment, depth: number, content: Fragment): Fragment {
  if (depth == 0) return fragment.append(content)
  return fragment.replaceChild(fragment.childCount - 1,
                               fragment.lastChild!.copy(addToFragment(fragment.lastChild!.content, depth - 1, content)))
}

function contentAt(fragment: Fragment, depth: number) {
  for (let i = 0; i < depth; i++) fragment = fragment.firstChild!.content
  return fragment
}

function closeNodeStart(node: Node, openStart: number, openEnd: number) {
  if (openStart <= 0) return node
  let frag = node.content
  if (openStart > 1)
    frag = frag.replaceChild(0, closeNodeStart(frag.firstChild!, openStart - 1, frag.childCount == 1 ? openEnd - 1 : 0))
  if (openStart > 0) {
    frag = node.type.contentMatch.fillBefore(frag)!.append(frag)
    if (openEnd <= 0) frag = frag.append(node.type.contentMatch.matchFragment(frag)!.fillBefore(Fragment.empty, true)!)
  }
  return node.copy(frag)
}

function contentAfterFits($to: ResolvedPos, depth: number, type: NodeType, match: ContentMatch, open: boolean) {
  let node = $to.node(depth), index = open ? $to.indexAfter(depth) : $to.index(depth)
  if (index == node.childCount && !type.compatibleContent(node.type)) return null
  let fit = match.fillBefore(node.content, true, index)
  return fit && !invalidMarks(type, node.content, index) ? fit : null
}

function invalidMarks(type: NodeType, fragment: Fragment, start: number) {
  for (let i = start; i < fragment.childCount; i++)
    if (!type.allowsMarks(fragment.child(i).marks)) return true
  return false
}

function definesContent(type: NodeType) {
  return type.spec.defining || type.spec.definingForContent
}

export function replaceRange(tr: Transform, from: number, to: number, slice: Slice) {
  if (!slice.size) return tr.deleteRange(from, to)

  let $from = tr.doc.resolve(from), $to = tr.doc.resolve(to)
  if (fitsTrivially($from, $to, slice))
    return tr.step(new ReplaceStep(from, to, slice))

  let targetDepths = coveredDepths($from, tr.doc.resolve(to))
  // Can't replace the whole document, so remove 0 if it's present
  if (targetDepths[targetDepths.length - 1] == 0) targetDepths.pop()
  // Negative numbers represent not expansion over the whole node at
  // that depth, but replacing from $from.before(-D) to $to.pos.
  let preferredTarget = -($from.depth + 1)
  targetDepths.unshift(preferredTarget)
  // This loop picks a preferred target depth, if one of the covering
  // depths is not outside of a defining node, and adds negative
  // depths for any depth that has $from at its start and does not
  // cross a defining node.
  for (let d = $from.depth, pos = $from.pos - 1; d > 0; d--, pos--) {
    let spec = $from.node(d).type.spec
    if (spec.defining || spec.definingAsContext || spec.isolating) break
    if (targetDepths.indexOf(d) > -1) preferredTarget = d
    else if ($from.before(d) == pos) targetDepths.splice(1, 0, -d)
  }
  // Try to fit each possible depth of the slice into each possible
  // target depth, starting with the preferred depths.
  let preferredTargetIndex = targetDepths.indexOf(preferredTarget)

  let leftNodes: Node[] = [], preferredDepth = slice.openStart
  for (let content = slice.content, i = 0;; i++) {
    let node = content.firstChild!
    leftNodes.push(node)
    if (i == slice.openStart) break
    content = node.content
  }

  // Back up preferredDepth to cover defining textblocks directly
  // above it, possibly skipping a non-defining textblock.
  for (let d = preferredDepth - 1; d >= 0; d--) {
    let leftNode = leftNodes[d], def = definesContent(leftNode.type)
    if (def && !leftNode.sameMarkup($from.node(Math.abs(preferredTarget) - 1))) preferredDepth = d
    else if (def || !leftNode.type.isTextblock) break
  }

  for (let j = slice.openStart; j >= 0; j--) {
    let openDepth = (j + preferredDepth + 1) % (slice.openStart + 1)
    let insert = leftNodes[openDepth]
    if (!insert) continue
    for (let i = 0; i < targetDepths.length; i++) {
      // Loop over possible expansion levels, starting with the
      // preferred one
      let targetDepth = targetDepths[(i + preferredTargetIndex) % targetDepths.length], expand = true
      if (targetDepth < 0) { expand = false; targetDepth = -targetDepth }
      let parent = $from.node(targetDepth - 1), index = $from.index(targetDepth - 1)
      if (parent.canReplaceWith(index, index, insert.type, insert.marks))
        return tr.replace($from.before(targetDepth), expand ? $to.after(targetDepth) : to,
                            new Slice(closeFragment(slice.content, 0, slice.openStart, openDepth),
                                      openDepth, slice.openEnd))
    }
  }

  let startSteps = tr.steps.length
  for (let i = targetDepths.length - 1; i >= 0; i--) {
    tr.replace(from, to, slice)
    if (tr.steps.length > startSteps) break
    let depth = targetDepths[i]
    if (depth < 0) continue
    from = $from.before(depth); to = $to.after(depth)
  }
}

function closeFragment(fragment: Fragment, depth: number, oldOpen: number, newOpen: number, parent?: Node) {
  if (depth < oldOpen) {
    let first = fragment.firstChild!
    fragment = fragment.replaceChild(0, first.copy(closeFragment(first.content, depth + 1, oldOpen, newOpen, first)))
  }
  if (depth > newOpen) {
    let match = parent!.contentMatchAt(0)!
    let start = match.fillBefore(fragment)!.append(fragment)
    fragment = start.append(match.matchFragment(start)!.fillBefore(Fragment.empty, true)!)
  }
  return fragment
}

export function replaceRangeWith(tr: Transform, from: number, to: number, node: Node) {
  if (!node.isInline && from == to && tr.doc.resolve(from).parent.content.size) {
    let point = insertPoint(tr.doc, from, node.type)
    if (point != null) from = to = point
  }
  tr.replaceRange(from, to, new Slice(Fragment.from(node), 0, 0))
}

export function deleteRange(tr: Transform, from: number, to: number) {
  let $from = tr.doc.resolve(from), $to = tr.doc.resolve(to)
  let covered = coveredDepths($from, $to)
  for (let i = 0; i < covered.length; i++) {
    let depth = covered[i], last = i == covered.length - 1
    if ((last && depth == 0) || $from.node(depth).type.contentMatch.validEnd)
      return tr.delete($from.start(depth), $to.end(depth))
    if (depth > 0 && (last || $from.node(depth - 1).canReplace($from.index(depth - 1), $to.indexAfter(depth - 1))))
      return tr.delete($from.before(depth), $to.after(depth))
  }
  for (let d = 1; d <= $from.depth && d <= $to.depth; d++) {
    if (from - $from.start(d) == $from.depth - d && to > $from.end(d) && $to.end(d) - to != $to.depth - d)
      return tr.delete($from.before(d), to)
  }
  tr.delete(from, to)
}

// Returns an array of all depths for which $from - $to spans the
// whole content of the nodes at that depth.
function coveredDepths($from: ResolvedPos, $to: ResolvedPos) {
  let result: number[] = [], minDepth = Math.min($from.depth, $to.depth)
  for (let d = minDepth; d >= 0; d--) {
    let start = $from.start(d)
    if (start < $from.pos - ($from.depth - d) ||
        $to.end(d) > $to.pos + ($to.depth - d) ||
        $from.node(d).type.spec.isolating ||
        $to.node(d).type.spec.isolating) break
    if (start == $to.start(d) ||
        (d == $from.depth && d == $to.depth && $from.parent.inlineContent && $to.parent.inlineContent &&
         d && $to.start(d - 1) == start - 1))
      result.push(d)
  }
  return result
}
