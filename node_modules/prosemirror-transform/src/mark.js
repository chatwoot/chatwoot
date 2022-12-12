import {MarkType, Slice, Fragment} from "prosemirror-model"

import {Transform} from "./transform"
import {AddMarkStep, RemoveMarkStep} from "./mark_step"
import {ReplaceStep} from "./replace_step"

// :: (number, number, Mark) → this
// Add the given mark to the inline content between `from` and `to`.
Transform.prototype.addMark = function(from, to, mark) {
  let removed = [], added = [], removing = null, adding = null
  this.doc.nodesBetween(from, to, (node, pos, parent) => {
    if (!node.isInline) return
    let marks = node.marks
    if (!mark.isInSet(marks) && parent.type.allowsMarkType(mark.type)) {
      let start = Math.max(pos, from), end = Math.min(pos + node.nodeSize, to)
      let newSet = mark.addToSet(marks)

      for (let i = 0; i < marks.length; i++) {
        if (!marks[i].isInSet(newSet)) {
          if (removing && removing.to == start && removing.mark.eq(marks[i]))
            removing.to = end
          else
            removed.push(removing = new RemoveMarkStep(start, end, marks[i]))
        }
      }

      if (adding && adding.to == start)
        adding.to = end
      else
        added.push(adding = new AddMarkStep(start, end, mark))
    }
  })

  removed.forEach(s => this.step(s))
  added.forEach(s => this.step(s))
  return this
}

// :: (number, number, ?union<Mark, MarkType>) → this
// Remove marks from inline nodes between `from` and `to`. When `mark`
// is a single mark, remove precisely that mark. When it is a mark type,
// remove all marks of that type. When it is null, remove all marks of
// any type.
Transform.prototype.removeMark = function(from, to, mark = null) {
  let matched = [], step = 0
  this.doc.nodesBetween(from, to, (node, pos) => {
    if (!node.isInline) return
    step++
    let toRemove = null
    if (mark instanceof MarkType) {
      let set = node.marks, found
      while (found = mark.isInSet(set)) {
        ;(toRemove || (toRemove = [])).push(found)
        set = found.removeFromSet(set)
      }
    } else if (mark) {
      if (mark.isInSet(node.marks)) toRemove = [mark]
    } else {
      toRemove = node.marks
    }
    if (toRemove && toRemove.length) {
      let end = Math.min(pos + node.nodeSize, to)
      for (let i = 0; i < toRemove.length; i++) {
        let style = toRemove[i], found
        for (let j = 0; j < matched.length; j++) {
          let m = matched[j]
          if (m.step == step - 1 && style.eq(matched[j].style)) found = m
        }
        if (found) {
          found.to = end
          found.step = step
        } else {
          matched.push({style, from: Math.max(pos, from), to: end, step})
        }
      }
    }
  })
  matched.forEach(m => this.step(new RemoveMarkStep(m.from, m.to, m.style)))
  return this
}

// :: (number, NodeType, ?ContentMatch) → this
// Removes all marks and nodes from the content of the node at `pos`
// that don't match the given new parent node type. Accepts an
// optional starting [content match](#model.ContentMatch) as third
// argument.
Transform.prototype.clearIncompatible = function(pos, parentType, match = parentType.contentMatch) {
  let node = this.doc.nodeAt(pos)
  let delSteps = [], cur = pos + 1
  for (let i = 0; i < node.childCount; i++) {
    let child = node.child(i), end = cur + child.nodeSize
    let allowed = match.matchType(child.type, child.attrs)
    if (!allowed) {
      delSteps.push(new ReplaceStep(cur, end, Slice.empty))
    } else {
      match = allowed
      for (let j = 0; j < child.marks.length; j++) if (!parentType.allowsMarkType(child.marks[j].type))
        this.step(new RemoveMarkStep(cur, end, child.marks[j]))
    }
    cur = end
  }
  if (!match.validEnd) {
    let fill = match.fillBefore(Fragment.empty, true)
    this.replace(cur, cur, new Slice(fill, 0, 0))
  }
  for (let i = delSteps.length - 1; i >= 0; i--) this.step(delSteps[i])
  return this
}
