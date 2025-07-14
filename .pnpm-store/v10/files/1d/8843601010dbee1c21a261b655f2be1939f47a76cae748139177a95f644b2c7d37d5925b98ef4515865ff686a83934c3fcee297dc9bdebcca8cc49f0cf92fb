"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var dlv_1 = __importDefault(require("dlv"));
function matches(event, matcher) {
    if (!matcher) {
        throw new Error('No matcher supplied!');
    }
    switch (matcher.type) {
        case 'all':
            return all();
        case 'fql':
            return fql(matcher.ir, event);
        default:
            throw new Error("Matcher of type ".concat(matcher.type, " unsupported."));
    }
}
exports.default = matches;
function all() {
    return true;
}
function fql(ir, event) {
    if (!ir) {
        return false;
    }
    try {
        ir = JSON.parse(ir);
    }
    catch (e) {
        throw new Error("Failed to JSON.parse FQL intermediate representation \"".concat(ir, "\": ").concat(e));
    }
    var result = fqlEvaluate(ir, event);
    if (typeof result !== 'boolean') {
        // An error was returned, or a lowercase, typeof, or similar function was run alone. Nothing to evaluate.
        return false;
    }
    return result;
}
// FQL is 100% type strict in Go. Show no mercy to types which do not comply.
function fqlEvaluate(ir, event) {
    // If the given ir chunk is not an array, then we should check the single given path or value for literally `true`.
    if (!Array.isArray(ir)) {
        return getValue(ir, event) === true;
    }
    // Otherwise, it is a sequence of ordered steps to follow to reach our solution!
    var item = ir[0];
    switch (item) {
        /*** Unary cases ***/
        // '!' => Invert the result
        case '!':
            return !fqlEvaluate(ir[1], event);
        /*** Binary cases ***/
        // 'or' => Any condition being true returns true
        case 'or':
            for (var i = 1; i < ir.length; i++) {
                if (fqlEvaluate(ir[i], event)) {
                    return true;
                }
            }
            return false;
        // 'and' => Any condition being false returns false
        case 'and':
            for (var i = 1; i < ir.length; i++) {
                if (!fqlEvaluate(ir[i], event)) {
                    return false;
                }
            }
            return true;
        // Equivalence comparisons
        case '=':
        case '!=':
            return compareItems(getValue(ir[1], event), getValue(ir[2], event), item, event);
        // Numerical comparisons
        case '<=':
        case '<':
        case '>':
        case '>=':
            // Compare the two values with the given operator.
            return compareNumbers(getValue(ir[1], event), getValue(ir[2], event), item, event);
        // item in [list]' => Checks whether item is in list
        case 'in':
            return checkInList(getValue(ir[1], event), getValue(ir[2], event), event);
        /*** Functions ***/
        // 'contains(str1, str2)' => The first string has a substring of the second string
        case 'contains':
            return contains(getValue(ir[1], event), getValue(ir[2], event));
        // 'match(str, match)' => The given string matches the provided glob matcher
        case 'match':
            return match(getValue(ir[1], event), getValue(ir[2], event));
        // 'lowercase(str)' => Returns a lowercased string, null if the item is not a string
        case 'lowercase':
            var target = getValue(ir[1], event);
            if (typeof target !== 'string') {
                return null;
            }
            return target.toLowerCase();
        // 'typeof(val)' => Returns the FQL type of the value
        case 'typeof':
            // TODO: Do we need mapping to allow for universal comparisons? e.g. Object -> JSON, Array -> List, Floats?
            return typeof getValue(ir[1], event);
        // 'length(val)' => Returns the length of an array or string, NaN if neither
        case 'length':
            return length(getValue(ir[1], event));
        // If nothing hit, we or the IR messed up somewhere.
        default:
            throw new Error("FQL IR could not evaluate for token: ".concat(item));
    }
}
function getValue(item, event) {
    // If item is an array, leave it as-is.
    if (Array.isArray(item)) {
        return item;
    }
    // If item is an object, it has the form of `{"value": VAL}`
    if (typeof item === 'object') {
        return item.value;
    }
    // Otherwise, it's an event path, e.g. "properties.email"
    return (0, dlv_1.default)(event, item);
}
function checkInList(item, list, event) {
    return list.find(function (it) { return getValue(it, event) === item; }) !== undefined;
}
function compareNumbers(first, second, operator, event) {
    // Check if it's more IR (such as a length() function)
    if (isIR(first)) {
        first = fqlEvaluate(first, event);
    }
    if (isIR(second)) {
        second = fqlEvaluate(second, event);
    }
    if (typeof first !== 'number' || typeof second !== 'number') {
        return false;
    }
    // Reminder: NaN is not comparable to any other number (including NaN) and will always return false as desired.
    switch (operator) {
        // '<=' => The first number is less than or equal to the second.
        case '<=':
            return first <= second;
        // '>=' => The first number is greater than or equal to the second
        case '>=':
            return first >= second;
        // '<' The first number is less than the second.
        case '<':
            return first < second;
        // '>' The first number is greater than the second.
        case '>':
            return first > second;
        default:
            throw new Error("Invalid operator in compareNumbers: ".concat(operator));
    }
}
function compareItems(first, second, operator, event) {
    // Check if it's more IR (such as a lowercase() function)
    if (isIR(first)) {
        first = fqlEvaluate(first, event);
    }
    if (isIR(second)) {
        second = fqlEvaluate(second, event);
    }
    if (typeof first === 'object' && typeof second === 'object') {
        first = JSON.stringify(first);
        second = JSON.stringify(second);
    }
    // Objects with the exact same contents AND order ARE considered identical. (Don't compare by reference)
    // Even in Go, this MUST be the same byte order.
    // e.g. {a: 1, b:2} === {a: 1, b:2} BUT {a:1, b:2} !== {b:2, a:1}
    // Maybe later we'll use a stable stringifier, but we're matching server-side behavior for now.
    switch (operator) {
        // '=' => The two following items are exactly identical
        case '=':
            return first === second;
        // '!=' => The two following items are NOT exactly identical.
        case '!=':
            return first !== second;
        default:
            throw new Error("Invalid operator in compareItems: ".concat(operator));
    }
}
function contains(first, second) {
    if (typeof first !== 'string' || typeof second !== 'string') {
        return false;
    }
    return first.indexOf(second) !== -1;
}
function match(str, glob) {
    if (typeof str !== 'string' || typeof glob !== 'string') {
        return false;
    }
    return globMatches(glob, str);
}
function length(item) {
    // Match server-side behavior.
    if (item === null) {
        return 0;
    }
    // Type-check to avoid returning .length of an object
    if (!Array.isArray(item) && typeof item !== 'string') {
        return NaN;
    }
    return item.length;
}
// This is a heuristic technically speaking, but should be close enough. The odds of someone trying to test
// a func with identical IR notation is pretty low.
function isIR(value) {
    // TODO: This can be better checked by checking if this is a {"value": THIS}
    if (!Array.isArray(value)) {
        return false;
    }
    // Function checks
    if ((value[0] === 'lowercase' || value[0] === 'length' || value[0] === 'typeof') &&
        value.length === 2) {
        return true;
    }
    if ((value[0] === 'contains' || value[0] === 'match') && value.length === 3) {
        return true;
    }
    return false;
}
// Any reputable glob matcher is designed to work on filesystems and doesn't allow the override of the separator
// character "/". This is problematic since our server-side representation e.g. evaluates "match('ab/c', 'a*)"
// as TRUE, whereas any glob matcher for JS available does false. So we're rewriting it here.
// See: https://github.com/segmentio/glob/blob/master/glob.go
function globMatches(pattern, str) {
    var _a, _b;
    Pattern: while (pattern.length > 0) {
        var star = void 0;
        var chunk = void 0;
        (_a = scanChunk(pattern), star = _a.star, chunk = _a.chunk, pattern = _a.pattern);
        if (star && chunk === '') {
            // Trailing * matches rest of string
            return true;
        }
        // Look for match at current position
        var _c = matchChunk(chunk, str), t = _c.t, ok = _c.ok, err = _c.err;
        if (err) {
            return false;
        }
        // If we're the last chunk, make sure we've exhausted the str
        // otherwise we'll give a false result even if we could still match
        // using the star
        if (ok && (t.length === 0 || pattern.length > 0)) {
            str = t;
            continue;
        }
        if (star) {
            // Look for match, skipping i+1 bytes.
            for (var i = 0; i < str.length; i++) {
                ;
                (_b = matchChunk(chunk, str.slice(i + 1)), t = _b.t, ok = _b.ok, err = _b.err);
                if (ok) {
                    // If we're the last chunk, make sure we exhausted the str.
                    if (pattern.length === 0 && t.length > 0) {
                        continue;
                    }
                    str = t;
                    continue Pattern;
                }
                if (err) {
                    return false;
                }
            }
        }
        return false;
    }
    return str.length === 0;
}
function scanChunk(pattern) {
    var result = {
        star: false,
        chunk: '',
        pattern: '',
    };
    while (pattern.length > 0 && pattern[0] === '*') {
        pattern = pattern.slice(1);
        result.star = true;
    }
    var inRange = false;
    var i;
    Scan: for (i = 0; i < pattern.length; i++) {
        switch (pattern[i]) {
            case '\\':
                // Error check handled in matchChunk: bad pattern.
                if (i + 1 < pattern.length) {
                    i++;
                }
                break;
            case '[':
                inRange = true;
                break;
            case ']':
                inRange = false;
                break;
            case '*':
                if (!inRange) {
                    break Scan;
                }
        }
    }
    result.chunk = pattern.slice(0, i);
    result.pattern = pattern.slice(i);
    return result;
}
// matchChunk checks whether chunk matches the beginning of s.
// If so, it returns the remainder of s (after the match).
// Chunk is all single-character operators: literals, char classes, and ?.
function matchChunk(chunk, str) {
    var _a, _b;
    var result = {
        t: '',
        ok: false,
        err: false,
    };
    while (chunk.length > 0) {
        if (str.length === 0) {
            return result;
        }
        switch (chunk[0]) {
            case '[':
                var char = str[0];
                str = str.slice(1);
                chunk = chunk.slice(1);
                var notNegated = true;
                if (chunk.length > 0 && chunk[0] === '^') {
                    notNegated = false;
                    chunk = chunk.slice(1);
                }
                // Parse all ranges
                var foundMatch = false;
                var nRange = 0;
                while (true) {
                    if (chunk.length > 0 && chunk[0] === ']' && nRange > 0) {
                        chunk = chunk.slice(1);
                        break;
                    }
                    var lo = '';
                    var hi = '';
                    var err = void 0;
                    (_a = getEsc(chunk), lo = _a.char, chunk = _a.newChunk, err = _a.err);
                    if (err) {
                        return result;
                    }
                    hi = lo;
                    if (chunk[0] === '-') {
                        ;
                        (_b = getEsc(chunk.slice(1)), hi = _b.char, chunk = _b.newChunk, err = _b.err);
                        if (err) {
                            return result;
                        }
                    }
                    if (lo <= char && char <= hi) {
                        foundMatch = true;
                    }
                    nRange++;
                }
                if (foundMatch !== notNegated) {
                    return result;
                }
                break;
            case '?':
                str = str.slice(1);
                chunk = chunk.slice(1);
                break;
            case '\\':
                chunk = chunk.slice(1);
                if (chunk.length === 0) {
                    result.err = true;
                    return result;
                }
            // Fallthrough, missing break intentional.
            default:
                if (chunk[0] !== str[0]) {
                    return result;
                }
                str = str.slice(1);
                chunk = chunk.slice(1);
        }
    }
    result.t = str;
    result.ok = true;
    result.err = false;
    return result;
}
// getEsc gets a possibly-escaped character from chunk, for a character class.
function getEsc(chunk) {
    var result = {
        char: '',
        newChunk: '',
        err: false,
    };
    if (chunk.length === 0 || chunk[0] === '-' || chunk[0] === ']') {
        result.err = true;
        return result;
    }
    if (chunk[0] === '\\') {
        chunk = chunk.slice(1);
        if (chunk.length === 0) {
            result.err = true;
            return result;
        }
    }
    // Unlike Go, JS strings operate on characters instead of bytes.
    // This is why we aren't copying over the GetRuneFromString stuff.
    result.char = chunk[0];
    result.newChunk = chunk.slice(1);
    if (result.newChunk.length === 0) {
        result.err = true;
    }
    return result;
}
//# sourceMappingURL=matchers.js.map