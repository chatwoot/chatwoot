// Copy-pasted from:
// https://github.com/substack/semver-compare/blob/master/index.js
//
// Inlining this function because some users reported issues with
// importing from `semver-compare` in a browser with ES6 "native" modules.
//
// Fixes `semver-compare` not being able to compare versions with alpha/beta/etc "tags".
// https://github.com/catamphetamine/libphonenumber-js/issues/381
export default function(a, b) {
    a = a.split('-')
    b = b.split('-')
    var pa = a[0].split('.')
    var pb = b[0].split('.')
    for (var i = 0; i < 3; i++) {
        var na = Number(pa[i])
        var nb = Number(pb[i])
        if (na > nb) return 1
        if (nb > na) return -1
        if (!isNaN(na) && isNaN(nb)) return 1
        if (isNaN(na) && !isNaN(nb)) return -1
    }
    if (a[1] && b[1]) {
        return a[1] > b[1] ? 1 : (a[1] < b[1] ? -1 : 0)
    }
    return !a[1] && b[1] ? 1 : (a[1] && !b[1] ? -1 : 0)
}