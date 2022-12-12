var test = require("tape")
var Result = require("rust-result")

var safeParse = require("../callback")
var safeParseTuple = require("../tuple")
var safeParseResult = require("../result")

test("safeParse is a function", function (assert) {
    assert.equal(typeof safeParse, "function")
    assert.end()
})

test("safeParse valid json", function (assert) {
    safeParse("{ \"foo\": true }", function (err, json) {
        assert.ifError(err)
        assert.equal(json.foo, true)

        assert.end()
    })
})

test("safeParse faulty", function (assert) {
    safeParse("WRONG", function (err) {
        assert.ok(err)
        assert.equal(err.message, "Unexpected token W")

        assert.end()
    })
})

test("safeParseTuple valid json", function (assert) {
    var t = safeParseTuple("{ \"foo\": true }")

    assert.ifError(t[0])
    assert.equal(t[1].foo, true)

    assert.end()
})

test("safeParseTuple faulty", function (assert) {
    var t = safeParseTuple("WRONG")

    assert.ok(t[0])
    assert.equal(t[0].message, "Unexpected token W")

    assert.end()
})

test("safeParseResult valid json", function (assert) {
    var t = safeParseResult("{ \"foo\": true }")

    assert.ifError(Result.isErr(t))
    assert.equal(Result.Ok(t).foo, true)

    assert.end()
})

test("safeParseResult faulty", function (assert) {
    var t = safeParseResult("WRONG")

    assert.ok(Result.Err(t))
    assert.equal(Result.Err(t).message, "Unexpected token W")

    assert.end()
})
