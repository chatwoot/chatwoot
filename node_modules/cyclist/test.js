var tape = require('tape')
var cyclist = require('./')

tape('basic put and get', function (t) {
  var list = cyclist(2)
  list.put(0, 'hello')
  list.put(1, 'world')
  t.same(list.get(0), 'hello')
  t.same(list.get(1), 'world')
  t.end()
})

tape('overflow put and get', function (t) {
  var list = cyclist(2)
  list.put(0, 'hello')
  list.put(1, 'world')
  list.put(2, 'verden')
  t.same(list.get(0), 'verden')
  t.same(list.get(1), 'world')
  t.same(list.get(2), 'verden')
  t.end()
})

tape('del', function (t) {
  var list = cyclist(2)
  list.put(0, 'hello')
  t.same(list.get(0), 'hello')
  list.del(0)
  t.ok(!list.get(0))
  t.end()
})

tape('multiple of two', function (t) {
  var list = cyclist(3)
  t.same(list.size, 4)
  t.end()
})
