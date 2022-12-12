import {Fragment, Slice} from "prosemirror-model"

import {ReplaceStep, ReplaceAroundStep} from "./replace_step"
import {Transform} from "./transform"
import {insertPoint} from "./structure"

// :: (Node, number, ?number, ?Slice) → ?Step
// ‘Fit’ a slice into a given position in the document, producing a
// [step](#transform.Step) that inserts it. Will return null if
// there's no meaningful way to insert the slice here, or inserting it
// would be a no-op (an empty slice over an empty range).
export function replaceStep(doc, from, to = from, slice = Slice.empty) {
  if (from == to && !slice.size) return null

  let $from = doc.resolve(from), $to = doc.resolve(to)
  // Optimization -- avoid work if it's obvious that it's not needed.
  if (fitsTrivially($from, $to, slice)) return new ReplaceStep(from, to, slice)
  return new Fitter($from, $to, slice).fit()
}

// :: (number, ?number, ?Slice) → this
// Replace the part of the document between `from` and `to` with the
// given `slice`.
Transform.prototype.replace = function(from, to = from, slice = Slice.empty) {
  let step = replaceStep(this.doc, from, to, slice)
  if (step) this.step(step)
  return this
}

// :: (number, number, union<Fragment, Node, [Node]>) → this
// Replace the given range with the given content, which may be a
// fragment, node, or array of nodes.
Transform.prototype.replaceWith = function(from, to, content) {
  return this.replace(from, to, new Slice(Fragment.from(content), 0, 0))
}

// :: (number, number) → this
// Delete the content between the given positions.
Transform.prototype.delete = function(from, to) {
  return this.replace(from, to, Slice.empty)
}

// :: (number, union<Fragment, Node, [Node]>) → this
// Insert the given content at the given position.
Transform.prototype.insert = function(pos, content) {
  return this.replaceWith(pos, pos, content)
}

function fitsTrivially($from, $to, slice) {
  return !slice.openStart && !slice.openEnd && $from.start() == $to.start() &&
    $from.parent.canReplace($from.index(), $to.index(), slice.content)
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
  constructor($from, $to, slice) {
    this.$to = $to
    this.$from = $from
    this.unplaced = slice

    this.frontier = []
    for (let i = 0; i <= $from.depth; i++) {
      let node = $from.node(i)
      this.frontier.push({
        type: node.type,
        match: node.contentMatchAt($from.indexAfter(i))
      })
    }

    this.placed = Fragment.empty
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
      content = content.firstChild.content
      openStart--; openEnd--
    }
    let slice = new Slice(content, openStart, openEnd)
    if (moveInline > -1)
      return new ReplaceAroundStep($from.pos, moveInline, this.$to.pos, this.$to.end(), slice, placedSize)
    if (slice.size || $from.pos != this.$to.pos) // Don't generate no-op steps
      return new ReplaceStep($from.pos, $to.pos, slice)
  }

  // Find a position on the start spine of `this.unplaced` that has
  // content that can be moved somewhere on the frontier. Returns two
  // depths, one for the slice and one for the frontier.
  findFittable() {
    // Only try wrapping nodes (pass 2) after finding a place without
    // wrapping failed.
    for (let pass = 1; pass <= 2; pass++) {
      for (let sliceDepth = this.unplaced.openStart; sliceDepth >= 0; sliceDepth--) {
        let fragment, parent
        if (sliceDepth) {
          parent = contentAt(this.unplaced.content, sliceDepth - 1).firstChild
          fragment = parent.content
        } else {
          fragment = this.unplaced.content
        }
        let first = fragment.firstChild
        for (let frontierDepth = this.depth; frontierDepth >= 0; frontierDepth--) {
          let {type, match} = this.frontier[frontierDepth], wrap, inject
          // In pass 1, if the next node matches, or there is no next
          // node but the parents look compatible, we've found a
          // place.
          if (pass == 1 && (first ? match.matchType(first.type) || (inject = match.fillBefore(Fragment.from(first), false))
                            : type.compatibleContent(parent.type)))
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
    if (!inner.childCount || inner.firstChild.isLeaf) return false
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

  // : ({sliceDepth: number, frontierDepth: number, parent: ?Node, wrap: ?[NodeType], inject: ?Fragment})
  // Move content from the unplaced slice at `sliceDepth` to the
  // frontier node at `frontierDepth`. Close that frontier node when
  // applicable.
  placeNodes({sliceDepth, frontierDepth, parent, inject, wrap}) {
    while (this.depth > frontierDepth) this.closeFrontierNode()
    if (wrap) for (let i = 0; i < wrap.length; i++) this.openFrontierNode(wrap[i])

    let slice = this.unplaced, fragment = parent ? parent.content : slice.content
    let openStart = slice.openStart - sliceDepth
    let taken = 0, add = []
    let {match, type} = this.frontier[frontierDepth]
    if (inject) {
      for (let i = 0; i < inject.childCount; i++) add.push(inject.child(i))
      match = match.matchFragment(inject)
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
      let node = cur.lastChild
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
    if (!this.$to.parent.isTextblock || this.$to.end() == this.$to.pos) return -1
    let top = this.frontier[this.depth], level
    if (!top.type.isTextblock || !contentAfterFits(this.$to, this.$to.depth, top.type, top.match, false) ||
        (this.$to.depth == this.depth && (level = this.findCloseLevel(this.$to)) && level.depth == this.depth)) return -1

    let {depth} = this.$to, after = this.$to.after(depth)
    while (depth > 1 && after == this.$to.end(--depth)) ++after
    return after
  }

  findCloseLevel($to) {
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

  close($to) {
    let close = this.findCloseLevel($to)
    if (!close) return null

    while (this.depth > close.depth) this.closeFrontierNode()
    if (close.fit.childCount) this.placed = addToFragment(this.placed, close.depth, close.fit)
    $to = close.move
    for (let d = close.depth + 1; d <= $to.depth; d++) {
      let node = $to.node(d), add = node.type.contentMatch.fillBefore(node.content, true, $to.index(d))
      this.openFrontierNode(node.type, node.attrs, add)
    }
    return $to
  }

  openFrontierNode(type, attrs, content) {
    let top = this.frontier[this.depth]
    top.match = top.match.matchType(type)
    this.placed = addToFragment(this.placed, this.depth, Fragment.from(type.create(attrs, content)))
    this.frontier.push({type, match: type.contentMatch})
  }

  closeFrontierNode() {
    let open = this.frontier.pop()
    let add = open.match.fillBefore(Fragment.empty, true)
    if (add.childCount) this.placed = addToFragment(this.placed, this.frontier.length, add)
  }
}

function dropFromFragment(fragment, depth, count) {
  if (depth == 0) return fragment.cutByIndex(count)
  return fragment.replaceChild(0, fragment.firstChild.copy(dropFromFragment(fragment.firstChild.content, depth - 1, count)))
}

function addToFragment(fragment, depth, content) {
  if (depth == 0) return fragment.append(content)
  return fragment.replaceChild(fragment.childCount - 1,
                               fragment.lastChild.copy(addToFragment(fragment.lastChild.content, depth - 1, content)))
}

function contentAt(fragment, depth) {
  for (let i = 0; i < depth; i++) fragment = fragment.firstChild.content
  return fragment
}

function closeNodeStart(node, openStart, openEnd) {
  if (openStart <= 0) return node
  let frag = node.content
  if (openStart > 1)
    frag = frag.replaceChild(0, closeNodeStart(frag.firstChild, openStart - 1, frag.childCount == 1 ? openEnd - 1 : 0))
  if (openStart > 0) {
    frag = node.type.contentMatch.fillBefore(frag).append(frag)
    if (openEnd <= 0) frag = frag.append(node.type.contentMatch.matchFragment(frag).fillBefore(Fragment.empty, true))
  }
  return node.copy(frag)
}

function contentAfterFits($to, depth, type, match, open) {
  let node = $to.node(depth), index = open ? $to.indexAfter(depth) : $to.index(depth)
  if (index == node.childCount && !type.compatibleContent(node.type)) return null
  let fit = match.fillBefore(node.content, true, index)
  return fit && !invalidMarks(type, node.content, index) ? fit : null
}

function invalidMarks(type, fragment, start) {
  for (let i = start; i < fragment.childCount; i++)
    if (!type.allowsMarks(fragment.child(i).marks)) return true
  return false
}

// :: (number, number, Slice) → this
// Replace a range of the document with a given slice, using `from`,
// `to`, and the slice's [`openStart`](#model.Slice.openStart) property
// as hints, rather than fixed start and end points. This method may
// grow the replaced area or close open nodes in the slice in order to
// get a fit that is more in line with WYSIWYG expectations, by
// dropping fully covered parent nodes of the replaced region when
// they are marked [non-defining](#model.NodeSpec.defining), or
// including an open parent node from the slice that _is_ marked as
// [defining](#model.NodeSpec.defining).
//
// This is the method, for example, to handle paste. The similar
// [`replace`](#transform.Transform.replace) method is a more
// primitive tool which will _not_ move the start and end of its given
// range, and is useful in situations where you need more precise
// control over what happens.
Transform.prototype.replaceRange = function(from, to, slice) {
  if (!slice.size) return this.deleteRange(from, to)

  let $from = this.doc.resolve(from), $to = this.doc.resolve(to)
  if (fitsTrivially($from, $to, slice))
    return this.step(new ReplaceStep(from, to, slice))

  let targetDepths = coveredDepths($from, this.doc.resolve(to))
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
    if (spec.defining || spec.isolating) break
    if (targetDepths.indexOf(d) > -1) preferredTarget = d
    else if ($from.before(d) == pos) targetDepths.splice(1, 0, -d)
  }
  // Try to fit each possible depth of the slice into each possible
  // target depth, starting with the preferred depths.
  let preferredTargetIndex = targetDepths.indexOf(preferredTarget)

  let leftNodes = [], preferredDepth = slice.openStart
  for (let content = slice.content, i = 0;; i++) {
    let node = content.firstChild
    leftNodes.push(node)
    if (i == slice.openStart) break
    content = node.content
  }
  // Back up if the node directly above openStart, or the node above
  // that separated only by a non-defining textblock node, is defining.
  if (preferredDepth > 0 && leftNodes[preferredDepth - 1].type.spec.defining &&
      $from.node(preferredTargetIndex).type != leftNodes[preferredDepth - 1].type)
    preferredDepth -= 1
  else if (preferredDepth >= 2 && leftNodes[preferredDepth - 1].isTextblock && leftNodes[preferredDepth - 2].type.spec.defining &&
           $from.node(preferredTargetIndex).type != leftNodes[preferredDepth - 2].type)
    preferredDepth -= 2

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
        return this.replace($from.before(targetDepth), expand ? $to.after(targetDepth) : to,
                            new Slice(closeFragment(slice.content, 0, slice.openStart, openDepth),
                                      openDepth, slice.openEnd))
    }
  }

  let startSteps = this.steps.length
  for (let i = targetDepths.length - 1; i >= 0; i--) {
    this.replace(from, to, slice)
    if (this.steps.length > startSteps) break
    let depth = targetDepths[i]
    if (depth < 0) continue
    from = $from.before(depth); to = $to.after(depth)
  }
  return this
}

function closeFragment(fragment, depth, oldOpen, newOpen, parent) {
  if (depth < oldOpen) {
    let first = fragment.firstChild
    fragment = fragment.replaceChild(0, first.copy(closeFragment(first.content, depth + 1, oldOpen, newOpen, first)))
  }
  if (depth > newOpen) {
    let match = parent.contentMatchAt(0)
    let start = match.fillBefore(fragment).append(fragment)
    fragment = start.append(match.matchFragment(start).fillBefore(Fragment.empty, true))
  }
  return fragment
}

// :: (number, number, Node) → this
// Replace the given range with a node, but use `from` and `to` as
// hints, rather than precise positions. When from and to are the same
// and are at the start or end of a parent node in which the given
// node doesn't fit, this method may _move_ them out towards a parent
// that does allow the given node to be placed. When the given range
// completely covers a parent node, this method may completely replace
// that parent node.
Transform.prototype.replaceRangeWith = function(from, to, node) {
  if (!node.isInline && from == to && this.doc.resolve(from).parent.content.size) {
    let point = insertPoint(this.doc, from, node.type)
    if (point != null) from = to = point
  }
  return this.replaceRange(from, to, new Slice(Fragment.from(node), 0, 0))
}

// :: (number, number) → this
// Delete the given range, expanding it to cover fully covered
// parent nodes until a valid replace is found.
Transform.prototype.deleteRange = function(from, to) {
  let $from = this.doc.resolve(from), $to = this.doc.resolve(to)
  let covered = coveredDepths($from, $to)
  for (let i = 0; i < covered.length; i++) {
    let depth = covered[i], last = i == covered.length - 1
    if ((last && depth == 0) || $from.node(depth).type.contentMatch.validEnd)
      return this.delete($from.start(depth), $to.end(depth))
    if (depth > 0 && (last || $from.node(depth - 1).canReplace($from.index(depth - 1), $to.indexAfter(depth - 1))))
      return this.delete($from.before(depth), $to.after(depth))
  }
  for (let d = 1; d <= $from.depth && d <= $to.depth; d++) {
    if (from - $from.start(d) == $from.depth - d && to > $from.end(d) && $to.end(d) - to != $to.depth - d)
      return this.delete($from.before(d), to)
  }
  return this.delete(from, to)
}

// : (ResolvedPos, ResolvedPos) → [number]
// Returns an array of all depths for which $from - $to spans the
// whole content of the nodes at that depth.
function coveredDepths($from, $to) {
  let result = [], minDepth = Math.min($from.depth, $to.depth)
  for (let d = minDepth; d >= 0; d--) {
    let start = $from.start(d)
    if (start < $from.pos - ($from.depth - d) ||
        $to.end(d) > $to.pos + ($to.depth - d) ||
        $from.node(d).type.spec.isolating ||
        $to.node(d).type.spec.isolating) break
    if (start == $to.start(d)) result.push(d)
  }
  return result
}
