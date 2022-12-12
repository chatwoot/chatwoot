const GOOD_LEAF_SIZE = 200

// :: class<T> A rope sequence is a persistent sequence data structure
// that supports appending, prepending, and slicing without doing a
// full copy. It is represented as a mostly-balanced tree.
class RopeSequence {
  // length:: number
  // The length of the rope.

  // :: (union<[T], RopeSequence<T>>) → RopeSequence<T>
  // Append an array or other rope to this one, returning a new rope.
  append(other) {
    if (!other.length) return this
    other = RopeSequence.from(other)

    return (!this.length && other) ||
      (other.length < GOOD_LEAF_SIZE && this.leafAppend(other)) ||
      (this.length < GOOD_LEAF_SIZE && other.leafPrepend(this)) ||
      this.appendInner(other)
  }

  // :: (union<[T], RopeSequence<T>>) → RopeSequence<T>
  // Prepend an array or other rope to this one, returning a new rope.
  prepend(other) {
    if (!other.length) return this
    return RopeSequence.from(other).append(this)
  }

  appendInner(other) {
    return new Append(this, other)
  }

  // :: (?number, ?number) → RopeSequence<T>
  // Create a rope repesenting a sub-sequence of this rope.
  slice(from = 0, to = this.length) {
    if (from >= to) return RopeSequence.empty
    return this.sliceInner(Math.max(0, from), Math.min(this.length, to))
  }

  // :: (number) → T
  // Retrieve the element at the given position from this rope.
  get(i) {
    if (i < 0 || i >= this.length) return undefined
    return this.getInner(i)
  }

  // :: ((element: T, index: number) → ?bool, ?number, ?number)
  // Call the given function for each element between the given
  // indices. This tends to be more efficient than looping over the
  // indices and calling `get`, because it doesn't have to descend the
  // tree for every element.
  forEach(f, from = 0, to = this.length) {
    if (from <= to)
      this.forEachInner(f, from, to, 0)
    else
      this.forEachInvertedInner(f, from, to, 0)
  }

  // :: ((element: T, index: number) → U, ?number, ?number) → [U]
  // Map the given functions over the elements of the rope, producing
  // a flat array.
  map(f, from = 0, to = this.length) {
    let result = []
    this.forEach((elt, i) => result.push(f(elt, i)), from, to)
    return result
  }

  // :: (?union<[T], RopeSequence<T>>) → RopeSequence<T>
  // Create a rope representing the given array, or return the rope
  // itself if a rope was given.
  static from(values) {
    if (values instanceof RopeSequence) return values
    return values && values.length ? new Leaf(values) : RopeSequence.empty
  }

  // flatten:: () → [T]
  // Return the content of this rope as an array.
}

class Leaf extends RopeSequence {
  constructor(values) {
    super()
    this.values = values
  }

  flatten() {
    return this.values
  }

  sliceInner(from, to) {
    if (from == 0 && to == this.length) return this
    return new Leaf(this.values.slice(from, to))
  }

  getInner(i) {
    return this.values[i]
  }

  forEachInner(f, from, to, start) {
    for (let i = from; i < to; i++)
      if (f(this.values[i], start + i) === false) return false
  }

  forEachInvertedInner(f, from, to, start) {
    for (let i = from - 1; i >= to; i--)
      if (f(this.values[i], start + i) === false) return false
  }

  leafAppend(other) {
    if (this.length + other.length <= GOOD_LEAF_SIZE)
      return new Leaf(this.values.concat(other.flatten()))
  }

  leafPrepend(other) {
    if (this.length + other.length <= GOOD_LEAF_SIZE)
      return new Leaf(other.flatten().concat(this.values))
  }

  get length() { return this.values.length }

  get depth() { return 0 }
}

// :: RopeSequence
// The empty rope sequence.
RopeSequence.empty = new Leaf([])

class Append extends RopeSequence {
  constructor(left, right) {
    super()
    this.left = left
    this.right = right
    this.length = left.length + right.length
    this.depth = Math.max(left.depth, right.depth) + 1
  }

  flatten() {
    return this.left.flatten().concat(this.right.flatten())
  }

  getInner(i) {
    return i < this.left.length ? this.left.get(i) : this.right.get(i - this.left.length)
  }

  forEachInner(f, from, to, start) {
    let leftLen = this.left.length
    if (from < leftLen &&
        this.left.forEachInner(f, from, Math.min(to, leftLen), start) === false)
      return false
    if (to > leftLen &&
        this.right.forEachInner(f, Math.max(from - leftLen, 0), Math.min(this.length, to) - leftLen, start + leftLen) === false)
      return false
  }

  forEachInvertedInner(f, from, to, start) {
    let leftLen = this.left.length
    if (from > leftLen &&
        this.right.forEachInvertedInner(f, from - leftLen, Math.max(to, leftLen) - leftLen, start + leftLen) === false)
      return false
    if (to < leftLen &&
        this.left.forEachInvertedInner(f, Math.min(from, leftLen), to, start) === false)
      return false
  }

  sliceInner(from, to) {
    if (from == 0 && to == this.length) return this
    let leftLen = this.left.length
    if (to <= leftLen) return this.left.slice(from, to)
    if (from >= leftLen) return this.right.slice(from - leftLen, to - leftLen)
    return this.left.slice(from, leftLen).append(this.right.slice(0, to - leftLen))
  }

  leafAppend(other) {
    let inner = this.right.leafAppend(other)
    if (inner) return new Append(this.left, inner)
  }

  leafPrepend(other) {
    let inner = this.left.leafPrepend(other)
    if (inner) return new Append(inner, this.right)
  }

  appendInner(other) {
    if (this.left.depth >= Math.max(this.right.depth, other.depth) + 1)
      return new Append(this.left, new Append(this.right, other))
    return new Append(this, other)
  }
}

module.exports = RopeSequence
