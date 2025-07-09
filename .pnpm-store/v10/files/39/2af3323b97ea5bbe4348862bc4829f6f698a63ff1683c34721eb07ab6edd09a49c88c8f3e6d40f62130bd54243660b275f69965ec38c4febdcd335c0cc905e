# rope-sequence

This module implements a single data type, `RopeSequence`, which is a
persistent sequence type implemented as a loosely-balanced
[rope](https://www.cs.rit.edu/usr/local/pub/jeh/courses/QUARTERS/FP/Labs/CedarRope/rope-paper.pdf).
It supports appending, prepending, and slicing without doing a full
copy. Random access is somewhat more expensive than in an array
(logarithmic, with some overhead), but should still be relatively
fast.

Licensed under the MIT license.

## class `RopeSequence<T>`

`static `**`from`**`(?union<[T], RopeSequence<T>>) → RopeSequence<T>`

Create a rope representing the given array, or return the rope itself
if a rope was given.

`static `**`empty`**`: RopeSequence<T>`

The empty rope.

**`length`**`: number`

The length of the rope.

**`append`**`(union<[T], RopeSequence<T>>) → RopeSequence<T>`

Append an array or other rope to this one, returning a new rope.

**`prepend`**`(union<[T], RopeSequence<T>>) → RopeSequence<T>`

Prepend an array or other rope to this one, returning a new rope.

**`slice`**`(from: ?number = 0, to: ?number = this.length) → RopeSequence<T>`

Create a rope repesenting a sub-sequence of this rope.

**`get`**`(index: number) → T`

Retrieve the element at the given position from this rope.

**`forEach`**`(f: fn(element: T, index: number) → ?bool, from: ?number, to: ?number)`

Call the given function for each element between the given indices.
This tends to be more efficient than looping over the indices and
calling `get`, because it doesn't have to descend the tree for every
element.

`to` may be less then `from`, in which case the iteration will happen
in reverse (starting at index `from - 1`, down to index `to`.

The iteration function may return `false` to abort iteration early.

**`map`**`(f: fn(element: T, index: number) → U, from: ?number, to: ?number) → [U]`

Map the given functions over the elements of the rope, producing a
flat array.

**`flatten`**`() → [T]`

Return the content of this rope as an array.
