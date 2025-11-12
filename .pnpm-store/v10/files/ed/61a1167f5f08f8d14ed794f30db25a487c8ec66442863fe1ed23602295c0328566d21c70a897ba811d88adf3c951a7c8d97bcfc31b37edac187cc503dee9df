module.exports = SafeParseCallback

function SafeParseCallback(obj, reviver, callback) {
    if (arguments.length === 2) {
        callback = reviver
        reviver = null
    }

    var json

    try {
        json = JSON.parse(obj, reviver)
    } catch (err) {
        return callback(err)
    }

    callback(null, json)
}
