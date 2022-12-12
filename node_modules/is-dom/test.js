'use strict'
var JSDOM = require('jsdom').JSDOM
var tape = require('tape')

var isDom = require('./index')

tape('is-dom', function (t) {
  var currentRealm = new JSDOM('<html><body></body></html>')
  var otherRealm = new JSDOM('<html><body></body></html>')
  global.window = currentRealm.window
  global.document = currentRealm.window.document

  t.test('should check if supplied argument is a dom node', function (t) {
    t.plan(17)
    t.equal(isDom(null), false)
    t.equal(isDom(null), false)
    t.equal(isDom(false), false)
    t.equal(isDom(new Date()), false)
    t.equal(isDom(), false)
    t.equal(isDom([]), false)
    t.equal(isDom(2), false)
    t.equal(isDom('foo'), false)
    t.equal(isDom(/asda/), false)
    t.equal(isDom({}), false)

    t.equal(isDom({ nodeType: 1, nodeName: 'BODY' }), true)
    t.equal(isDom(document.createElement('body')), true)
    t.equal(isDom(window), false)
    t.equal(isDom(document), true)

    t.equal(isDom(otherRealm.window), false)
    t.equal(isDom(otherRealm.window.document), true)
    t.equal(isDom(otherRealm.window.document.createElement('body')), true)
  })
})
