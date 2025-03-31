var test = require('tape')

var Result = require('./index.js')

test('can create Ok', function t(assert) {
  var v = Result.Ok(42)

  assert.equal(!!v, true)
  assert.equal(v.v, 42)

  assert.end()
})

test('can check for Ok', function t(assert) {
  var result = Result.Ok(42)

  assert.equal(Result.isOk(result), true)
  assert.equal(Result.Ok(result), 42)

  assert.end()
})

test('check for Ok fails for Err', function t(assert) {
  var result = Result.Err(new Error('foo'))

  assert.equal(Result.isOk(result), false)
  assert.equal(Result.Ok(result), undefined)

  assert.end()
})

test('can create Err', function t(assert) {
  var err = Result.Err(new Error('foo'))

  assert.equal(!!err, true)
  assert.equal(err.err.message, 'foo')

  assert.end()
})

test('can check for Err', function t(assert) {
  var result = Result.Err(new Error('foo'))

  assert.equal(Result.isErr(result), true)
  assert.equal(Result.Err(result).message, 'foo')

  assert.end()
})

test('check for Err fails for Ok', function t(assert) {
  var result = Result.Ok(42)

  assert.equal(Result.isErr(result), false)
  assert.equal(Result.Err(result), undefined)

  assert.end()
})

test('Ok can support null value', function t(assert) {
  var result = Result.Ok(null)

  assert.equal(!!result, true)
  assert.equal(result.v, null)

  assert.equal(Result.isOk(result), true)
  assert.equal(Result.Ok(result), null)

  assert.equal(Result.isErr(result), false)
  assert.equal(Result.Err(result), undefined)

  assert.end()
})

test('Ok throws if you box undefined', function t(assert) {
  assert.throws(function () {
    Result.Ok(undefined)
  }, /Cannot box `undefined` in Result.Ok/)

  assert.end()
})

test('Err throws if you box non-error', function t(assert) {
  assert.throws(function () {
    Result.Err(42)
  }, /Cannot box a non-error in Result.Err/)

  assert.end()
})
