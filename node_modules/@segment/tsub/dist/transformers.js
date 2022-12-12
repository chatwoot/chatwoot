"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var md5_1 = __importDefault(require("tiny-hashes/md5"));
var dlv_1 = __importDefault(require("dlv"));
var math_base_special_ldexp_1 = __importDefault(require("@stdlib/math-base-special-ldexp"));
var dset_1 = require("dset");
var unset_1 = require("./unset");
function transform(payload, transformers) {
    var transformedPayload = payload;
    for (var _i = 0, transformers_1 = transformers; _i < transformers_1.length; _i++) {
        var transformer = transformers_1[_i];
        switch (transformer.type) {
            case 'drop':
                return null;
            case 'drop_properties':
                dropProperties(transformedPayload, transformer.config);
                break;
            case 'allow_properties':
                allowProperties(transformedPayload, transformer.config);
                break;
            case 'sample_event':
                if (sampleEvent(transformedPayload, transformer.config)) {
                    break;
                }
                return null;
            case 'map_properties':
                mapProperties(transformedPayload, transformer.config);
                break;
            case 'hash_properties':
                // Not yet supported, but don't throw an error. Just ignore.
                break;
            default:
                throw new Error("Transformer of type \"".concat(transformer.type, "\" is unsupported."));
        }
    }
    return transformedPayload;
}
exports.default = transform;
// dropProperties removes all specified props from the object.
function dropProperties(payload, config) {
    for (var key in config.drop) {
        if (!config.drop.hasOwnProperty(key)) {
            continue;
        }
        // If key is empty, it refers to the top-level object.
        var field = key === '' ? payload : (0, dlv_1.default)(payload, key);
        // Can only drop props off of arrays and objects.
        if (typeof field !== 'object' || field === null) {
            continue;
        }
        for (var _i = 0, _a = config.drop[key]; _i < _a.length; _i++) {
            var target = _a[_i];
            delete field[target];
        }
    }
}
// allowProperties ONLY allows the specific targets within the keys. (e.g. "a.foo": ["bar", "baz"]
// on {a: {foo: {bar: 1, baz: 2}, other: 3}} will not have any drops, as it only looks inside a.foo
function allowProperties(payload, config) {
    for (var key in config.allow) {
        if (!config.allow.hasOwnProperty(key)) {
            continue;
        }
        // If key is empty, it refers to the top-level object.
        var field = key === '' ? payload : (0, dlv_1.default)(payload, key);
        // Can only drop props off of arrays and objects.
        if (typeof field !== 'object' || field === null) {
            continue;
        }
        // Execution order fortunately doesn't really matter (e.g. if someone filtered off of foo.bar, then foo.bar.baz)
        // except for micro-optimization.
        for (var k in field) {
            if (!field.hasOwnProperty(k)) {
                continue;
            }
            if (config.allow[key].indexOf(k) === -1) {
                delete field[k];
            }
        }
    }
}
function mapProperties(payload, config) {
    // Some configs might try to modify or read from a field multiple times. We will only ever read
    // values as they were before any modifications began. Thus, if you try to override e.g.
    // {a: {b: 1}} with set(a, 'b', 2) (which results in {a: {b: 2}}) and then try to copy a.b into
    // a.c, you will get {a: {b: 2, c:1}} and NOT {a: {b:2, c:2}}. This prevents map evaluation
    // order from mattering, and === what server-side does.
    // See: https://github.com/segmentio/tsub/blob/661695a63b60b90471796e667458f076af788c19/transformers/map_properties.go#L179-L200
    var initialPayload = JSON.parse(JSON.stringify(payload));
    for (var key in config.map) {
        if (!config.map.hasOwnProperty(key)) {
            continue;
        }
        var actionMap = config.map[key];
        // Can't manipulate non-objects. Check that the parent is one. Strip the last .field
        // from the string.
        var splitKey = key.split('.');
        var parent_1 = void 0;
        if (splitKey.length > 1) {
            splitKey.pop();
            parent_1 = (0, dlv_1.default)(initialPayload, splitKey.join('.'));
        }
        else {
            parent_1 = payload;
        }
        if (typeof parent_1 !== 'object') {
            continue;
        }
        // These actions are exclusive to each other.
        if (actionMap.copy) {
            var valueToCopy = (0, dlv_1.default)(initialPayload, actionMap.copy);
            if (valueToCopy !== undefined) {
                (0, dset_1.dset)(payload, key, valueToCopy);
            }
        }
        else if (actionMap.move) {
            var valueToMove = (0, dlv_1.default)(initialPayload, actionMap.move);
            if (valueToMove !== undefined) {
                (0, dset_1.dset)(payload, key, valueToMove);
            }
            (0, unset_1.unset)(payload, actionMap.move);
        }
        // Have to check only if property exists, as null, undefined, and other vals could be explicitly set.
        else if (actionMap.hasOwnProperty('set')) {
            (0, dset_1.dset)(payload, key, actionMap.set);
        }
        // to_string is not exclusive and can be paired with other actions. Final action.
        if (actionMap.to_string) {
            var valueToString = (0, dlv_1.default)(payload, key);
            // Do not string arrays and objects. Do not double-encode strings.
            if (typeof valueToString === 'string' ||
                (typeof valueToString === 'object' && valueToString !== null)) {
                continue;
            }
            // TODO: Check stringifier in Golang for parity.
            if (valueToString !== undefined) {
                (0, dset_1.dset)(payload, key, JSON.stringify(valueToString));
            }
            else {
                // TODO: Check this behavior.
                (0, dset_1.dset)(payload, key, 'undefined');
            }
        }
    }
}
function sampleEvent(payload, config) {
    if (config.sample.percent <= 0) {
        return false;
    }
    else if (config.sample.percent >= 1) {
        return true;
    }
    // If we're not filtering deterministically, just use raw percentage.
    if (!config.sample.path) {
        return samplePercent(config.sample.percent);
    }
    // Otherwise, use a deterministic hash.
    return sampleConsistentPercent(payload, config);
}
function samplePercent(percent) {
    // Math.random returns [0, 1) => 0.0<>0.9999...
    return Math.random() <= percent;
}
// sampleConsistentPercent converts an input string of bytes into a consistent uniform
// continuous distribution of [0.0, 1.0]. This is based on
// http://mumble.net/~campbell/tmp/random_real.c, but using the digest
// result of the input value as the random information.
// IMPORTANT - This function needs to === the Golang implementation to ensure that the two return the same vals!
// See: https://github.com/segmentio/sampler/blob/65cb04132305a04fcd4bcaef67d57fbe40c30241/sampler.go#L13-L38
// Since AJS supports IE9+ (typed arrays were introduced in IE10) we're doing some manual array math.
// This could be done directly with strings, but arrays are easier to reason about/have better function support.
function sampleConsistentPercent(payload, config) {
    var field = (0, dlv_1.default)(payload, config.sample.path);
    // Operate off of JSON bytes. TODO: Validate all type behavior, esp. strings.
    var digest = (0, md5_1.default)(JSON.stringify(field));
    var exponent = -64;
    // Manually maintain 64-bit int as an array.
    var significand = [];
    // Left-shift and OR for first 8 bytes of digest. (8 bytes * 8 = 64 bits)
    consumeDigest(digest.slice(0, 8), significand);
    var leadingZeros = 0;
    for (var i = 0; i < 64; i++) {
        if (significand[i] === 1) {
            break;
        }
        leadingZeros++;
    }
    if (leadingZeros !== 0) {
        // Use the last 8 bytes of the digest, same as before.
        var val = [];
        consumeDigest(digest.slice(9, 16), val);
        exponent -= leadingZeros;
        // Left-shift away leading zeros in significand.
        significand.splice(0, leadingZeros);
        // Right-shift val by 64 minus leading zeros and push into significand.
        val.splice(64 - leadingZeros);
        significand = significand.concat(val);
    }
    // Flip 64th bit
    significand[63] = significand[63] === 0 ? 1 : 0;
    // Convert our manual binary into a JS num (binary arr => binary string => psuedo-int) and run the ldexp!
    return (0, math_base_special_ldexp_1.default)(parseInt(significand.join(''), 2), exponent) < config.sample.percent;
}
// Array byte filler helper
function consumeDigest(digest, arr) {
    for (var i = 0; i < 8; i++) {
        var remainder = digest[i];
        for (var binary = 128; binary >= 1; binary /= 2) {
            if (remainder - binary >= 0) {
                remainder -= binary;
                arr.push(1);
            }
            else {
                arr.push(0);
            }
        }
    }
}
//# sourceMappingURL=transformers.js.map