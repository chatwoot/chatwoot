var RopeSequence = require("./index")
var assert = require("assert")

function describe(rope) {
  if (rope.left) return "(" + describe(rope.left) + ", " + describe(rope.right) + ")"
  else return rope.length
}

function appendBuild(n) {
  var rope = RopeSequence.empty
  for (var i = 0; i < n; i++)
    rope = rope.append([i])
  return rope
}

function dequeBuild(n) {
  var mid = n >> 1, rope = RopeSequence.empty
  for (var from = mid - 1, to = mid; to < n; from--, to++) {
    rope = rope.append([to])
    if (from >= 0) rope = RopeSequence.from([from]).append(rope)
  }
  return rope
}

function flatBuild(n) {
  var arr = []
  for (var i = 0; i < n; i++) arr.push(i)
  return RopeSequence.from(arr)
}

var SIZE = 10000

function checkForEach(rope, name, start, end, offset) {
  var cur = start
  rope.forEach(function(elt, i) {
    assert.equal(elt, cur + offset, "Proper element at " + cur + " in " + name)
    assert.equal(cur, i, "Accurate index passed")
    cur++
  }, start, end)
  assert.equal(cur, end, "Enough elements iterated in " + name)
  rope.forEach(function(elt, i) {
    cur--
    assert.equal(elt, cur + offset, "Proper element during reverse iter at " + cur + " in " + name)
    assert.equal(cur, i, "Accurate index passed by reverse iter")
  }, end, start)
  assert.equal(cur, start, "Enough elements reverse-iterated in " + name + " -- " + cur + " " + start)
}

function check(rope, size, name, offset) {
  if (!offset) offset = 0
  assert.equal(rope.length, size, "Size of " + name)
  for (var i = 0; i < rope.length; i++)
    assert.equal(rope.get(i), offset + i, "Field at " + i + " in " + name)
  checkForEach(rope, name, 0, rope.length, offset)
  for (var i = 0, e = Math.min(10, Math.floor(size / 100)); i < e; i++) {
    var start = Math.floor(Math.random() * size), end = start + Math.ceil(Math.random() * (size - start))
    checkForEach(rope, name + "-" + start + "-" + end, start, end, offset)
    check(rope.slice(start, end), end - start, name + "-sliced-" + start + "-" + end, offset + start)
  }
}

check(appendBuild(SIZE), SIZE, "appended")
check(dequeBuild(SIZE), SIZE, "dequed")
check(flatBuild(SIZE), SIZE, "flat")

var small = RopeSequence.from([1, 2, 4]), empty = RopeSequence.empty
assert.equal(small.append(empty), small, "ID append")
assert.equal(small.prepend(empty), small, "ID prepend")
assert.equal(empty.append(empty), empty, "empty append")
assert.equal(small.slice(0, 0), empty, "empty slice")

var sum = 0
small.forEach(function(v) { if (v == 2) return false; sum += v })
assert.equal(sum, 1, "abort iteration")

assert.deepEqual(small.map(function(x) { return x + 1 }), [2, 3, 5], "mapping")

console.log("All passed")
