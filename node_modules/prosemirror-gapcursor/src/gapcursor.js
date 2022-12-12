import {Selection, NodeSelection} from "prosemirror-state"
import {Slice} from "prosemirror-model"

// ::- Gap cursor selections are represented using this class. Its
// `$anchor` and `$head` properties both point at the cursor position.
export class GapCursor extends Selection {
  // : (ResolvedPos)
  constructor($pos) {
    super($pos, $pos)
  }

  map(doc, mapping) {
    let $pos = doc.resolve(mapping.map(this.head))
    return GapCursor.valid($pos) ? new GapCursor($pos) : Selection.near($pos)
  }

  content() { return Slice.empty }

  eq(other) {
    return other instanceof GapCursor && other.head == this.head
  }

  toJSON() {
    return {type: "gapcursor", pos: this.head}
  }

  static fromJSON(doc, json) {
    if (typeof json.pos != "number") throw new RangeError("Invalid input for GapCursor.fromJSON")
    return new GapCursor(doc.resolve(json.pos))
  }

  getBookmark() { return new GapBookmark(this.anchor) }

  static valid($pos) {
    let parent = $pos.parent
    if (parent.isTextblock || !closedBefore($pos) || !closedAfter($pos)) return false
    let override = parent.type.spec.allowGapCursor
    if (override != null) return override
    let deflt = parent.contentMatchAt($pos.index()).defaultType
    return deflt && deflt.isTextblock
  }

  static findFrom($pos, dir, mustMove) {
    search: for (;;) {
      if (!mustMove && GapCursor.valid($pos)) return $pos
      let pos = $pos.pos, next = null
      // Scan up from this position
      for (let d = $pos.depth;; d--) {
        let parent = $pos.node(d)
        if (dir > 0 ? $pos.indexAfter(d) < parent.childCount : $pos.index(d) > 0) {
          next = parent.child(dir > 0 ? $pos.indexAfter(d) : $pos.index(d) - 1)
          break
        } else if (d == 0) {
          return null
        }
        pos += dir
        let $cur = $pos.doc.resolve(pos)
        if (GapCursor.valid($cur)) return $cur
      }

      // And then down into the next node
      for (;;) {
        let inside = dir > 0 ? next.firstChild : next.lastChild
        if (!inside) {
          if (next.isAtom && !next.isText && !NodeSelection.isSelectable(next)) {
            $pos = $pos.doc.resolve(pos + next.nodeSize * dir)
            mustMove = false
            continue search
          }
          break
        }
        next = inside
        pos += dir
        let $cur = $pos.doc.resolve(pos)
        if (GapCursor.valid($cur)) return $cur
      }

      return null
    }
  }
}

GapCursor.prototype.visible = false

Selection.jsonID("gapcursor", GapCursor)

class GapBookmark {
  constructor(pos) {
    this.pos = pos
  }
  map(mapping) {
    return new GapBookmark(mapping.map(this.pos))
  }
  resolve(doc) {
    let $pos = doc.resolve(this.pos)
    return GapCursor.valid($pos) ? new GapCursor($pos) : Selection.near($pos)
  }
}

function closedBefore($pos) {
  for (let d = $pos.depth; d >= 0; d--) {
    let index = $pos.index(d)
    // At the start of this parent, look at next one
    if (index == 0) continue
    // See if the node before (or its first ancestor) is closed
    for (let before = $pos.node(d).child(index - 1);; before = before.lastChild) {
      if ((before.childCount == 0 && !before.inlineContent) || before.isAtom || before.type.spec.isolating) return true
      if (before.inlineContent) return false
    }
  }
  // Hit start of document
  return true
}

function closedAfter($pos) {
  for (let d = $pos.depth; d >= 0; d--) {
    let index = $pos.indexAfter(d), parent = $pos.node(d)
    if (index == parent.childCount) continue
    for (let after = parent.child(index);; after = after.firstChild) {
      if ((after.childCount == 0 && !after.inlineContent) || after.isAtom || after.type.spec.isolating) return true
      if (after.inlineContent) return false
    }
  }
  return true
}
