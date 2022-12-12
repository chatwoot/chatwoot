var test = require('tape')
var clamp = require('./')

test('clamp', function(t) {
  t.equal(clamp(0, -100, 100), 0)
  t.equal(clamp(0, 100, 100),  100)
  t.equal(clamp(0, 100, -100), 0)
  t.equal(clamp(100, 0, 50), 50)
  t.equal(clamp(50, 100, 150), 100)
  t.end()
})
