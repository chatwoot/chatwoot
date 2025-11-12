"use strict";
/**
 * uuidv7: An experimental implementation of the proposed UUID Version 7
 *
 * @license Apache-2.0
 * @copyright 2021-2023 LiosK
 * @packageDocumentation
 *
 * from https://github.com/LiosK/uuidv7/blob/e501462ea3d23241de13192ceae726956f9b3b7d/src/index.ts
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.uuid7ToTimestampMs = exports.uuidv7 = exports.UUID = void 0;
// polyfill for IE11
var globals_1 = require("./utils/globals");
var core_1 = require("@posthog/core");
if (!Math.trunc) {
    Math.trunc = function (v) {
        return v < 0 ? Math.ceil(v) : Math.floor(v);
    };
}
// polyfill for IE11
if (!Number.isInteger) {
    Number.isInteger = function (value) {
        return (0, core_1.isNumber)(value) && isFinite(value) && Math.floor(value) === value;
    };
}
var DIGITS = '0123456789abcdef';
/** Represents a UUID as a 16-byte byte array. */
var UUID = /** @class */ (function () {
    /** @param bytes - The 16-byte byte array representation. */
    function UUID(bytes) {
        this.bytes = bytes;
        if (bytes.length !== 16) {
            throw new TypeError('not 128-bit length');
        }
    }
    /**
     * Builds a byte array from UUIDv7 field values.
     *
     * @param unixTsMs - A 48-bit `unix_ts_ms` field value.
     * @param randA - A 12-bit `rand_a` field value.
     * @param randBHi - The higher 30 bits of 62-bit `rand_b` field value.
     * @param randBLo - The lower 32 bits of 62-bit `rand_b` field value.
     */
    UUID.fromFieldsV7 = function (unixTsMs, randA, randBHi, randBLo) {
        if (!Number.isInteger(unixTsMs) ||
            !Number.isInteger(randA) ||
            !Number.isInteger(randBHi) ||
            !Number.isInteger(randBLo) ||
            unixTsMs < 0 ||
            randA < 0 ||
            randBHi < 0 ||
            randBLo < 0 ||
            unixTsMs > 281474976710655 ||
            randA > 0xfff ||
            randBHi > 1073741823 ||
            randBLo > 4294967295) {
            throw new RangeError('invalid field value');
        }
        var bytes = new Uint8Array(16);
        bytes[0] = unixTsMs / Math.pow(2, 40);
        bytes[1] = unixTsMs / Math.pow(2, 32);
        bytes[2] = unixTsMs / Math.pow(2, 24);
        bytes[3] = unixTsMs / Math.pow(2, 16);
        bytes[4] = unixTsMs / Math.pow(2, 8);
        bytes[5] = unixTsMs;
        bytes[6] = 0x70 | (randA >>> 8);
        bytes[7] = randA;
        bytes[8] = 0x80 | (randBHi >>> 24);
        bytes[9] = randBHi >>> 16;
        bytes[10] = randBHi >>> 8;
        bytes[11] = randBHi;
        bytes[12] = randBLo >>> 24;
        bytes[13] = randBLo >>> 16;
        bytes[14] = randBLo >>> 8;
        bytes[15] = randBLo;
        return new UUID(bytes);
    };
    /** @returns The 8-4-4-4-12 canonical hexadecimal string representation. */
    UUID.prototype.toString = function () {
        var text = '';
        for (var i = 0; i < this.bytes.length; i++) {
            text = text + DIGITS.charAt(this.bytes[i] >>> 4) + DIGITS.charAt(this.bytes[i] & 0xf);
            if (i === 3 || i === 5 || i === 7 || i === 9) {
                text += '-';
            }
        }
        if (text.length !== 36) {
            // We saw one customer whose bundling code was mangling the UUID generation
            // rather than accept a bad UUID, we throw an error here.
            throw new Error('Invalid UUIDv7 was generated');
        }
        return text;
    };
    /** Creates an object from `this`. */
    UUID.prototype.clone = function () {
        return new UUID(this.bytes.slice(0));
    };
    /** Returns true if `this` is equivalent to `other`. */
    UUID.prototype.equals = function (other) {
        return this.compareTo(other) === 0;
    };
    /**
     * Returns a negative integer, zero, or positive integer if `this` is less
     * than, equal to, or greater than `other`, respectively.
     */
    UUID.prototype.compareTo = function (other) {
        for (var i = 0; i < 16; i++) {
            var diff = this.bytes[i] - other.bytes[i];
            if (diff !== 0) {
                return Math.sign(diff);
            }
        }
        return 0;
    };
    return UUID;
}());
exports.UUID = UUID;
/** Encapsulates the monotonic counter state. */
var V7Generator = /** @class */ (function () {
    function V7Generator() {
        this._timestamp = 0;
        this._counter = 0;
        this._random = new DefaultRandom();
    }
    /**
     * Generates a new UUIDv7 object from the current timestamp, or resets the
     * generator upon significant timestamp rollback.
     *
     * This method returns monotonically increasing UUIDs unless the up-to-date
     * timestamp is significantly (by ten seconds or more) smaller than the one
     * embedded in the immediately preceding UUID. If such a significant clock
     * rollback is detected, this method resets the generator and returns a new
     * UUID based on the current timestamp.
     */
    V7Generator.prototype.generate = function () {
        var value = this.generateOrAbort();
        if (!(0, core_1.isUndefined)(value)) {
            return value;
        }
        else {
            // reset state and resume
            this._timestamp = 0;
            var valueAfterReset = this.generateOrAbort();
            if ((0, core_1.isUndefined)(valueAfterReset)) {
                throw new Error('Could not generate UUID after timestamp reset');
            }
            return valueAfterReset;
        }
    };
    /**
     * Generates a new UUIDv7 object from the current timestamp, or returns
     * `undefined` upon significant timestamp rollback.
     *
     * This method returns monotonically increasing UUIDs unless the up-to-date
     * timestamp is significantly (by ten seconds or more) smaller than the one
     * embedded in the immediately preceding UUID. If such a significant clock
     * rollback is detected, this method aborts and returns `undefined`.
     */
    V7Generator.prototype.generateOrAbort = function () {
        var MAX_COUNTER = 4398046511103;
        var ROLLBACK_ALLOWANCE = 10000; // 10 seconds
        var ts = Date.now();
        if (ts > this._timestamp) {
            this._timestamp = ts;
            this._resetCounter();
        }
        else if (ts + ROLLBACK_ALLOWANCE > this._timestamp) {
            // go on with previous timestamp if new one is not much smaller
            this._counter++;
            if (this._counter > MAX_COUNTER) {
                // increment timestamp at counter overflow
                this._timestamp++;
                this._resetCounter();
            }
        }
        else {
            // abort if clock went backwards to unbearable extent
            return undefined;
        }
        return UUID.fromFieldsV7(this._timestamp, Math.trunc(this._counter / Math.pow(2, 30)), this._counter & (Math.pow(2, 30) - 1), this._random.nextUint32());
    };
    /** Initializes the counter at a 42-bit random integer. */
    V7Generator.prototype._resetCounter = function () {
        this._counter = this._random.nextUint32() * 0x400 + (this._random.nextUint32() & 0x3ff);
    };
    return V7Generator;
}());
/** Stores `crypto.getRandomValues()` available in the environment. */
var getRandomValues = function (buffer) {
    // fall back on Math.random() unless the flag is set to true
    // TRICKY: don't use the isUndefined method here as can't pass the reference
    if (typeof UUIDV7_DENY_WEAK_RNG !== 'undefined' && UUIDV7_DENY_WEAK_RNG) {
        throw new Error('no cryptographically strong RNG available');
    }
    for (var i = 0; i < buffer.length; i++) {
        buffer[i] = Math.trunc(Math.random() * 65536) * 65536 + Math.trunc(Math.random() * 65536);
    }
    return buffer;
};
// detect Web Crypto API
if (globals_1.window && !(0, core_1.isUndefined)(globals_1.window.crypto) && crypto.getRandomValues) {
    getRandomValues = function (buffer) { return crypto.getRandomValues(buffer); };
}
/**
 * Wraps `crypto.getRandomValues()` and compatibles to enable buffering; this
 * uses a small buffer by default to avoid unbearable throughput decline in some
 * environments as well as the waste of time and space for unused values.
 */
var DefaultRandom = /** @class */ (function () {
    function DefaultRandom() {
        this._buffer = new Uint32Array(8);
        this._cursor = Infinity;
    }
    DefaultRandom.prototype.nextUint32 = function () {
        if (this._cursor >= this._buffer.length) {
            getRandomValues(this._buffer);
            this._cursor = 0;
        }
        return this._buffer[this._cursor++];
    };
    return DefaultRandom;
}());
var defaultGenerator;
/**
 * Generates a UUIDv7 string.
 *
 * @returns The 8-4-4-4-12 canonical hexadecimal string representation
 * ("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx").
 */
var uuidv7 = function () { return uuidv7obj().toString(); };
exports.uuidv7 = uuidv7;
/** Generates a UUIDv7 object. */
var uuidv7obj = function () { return (defaultGenerator || (defaultGenerator = new V7Generator())).generate(); };
var uuid7ToTimestampMs = function (uuid) {
    // remove hyphens
    var hex = uuid.replace(/-/g, '');
    // ensure that it's a version 7 UUID
    if (hex.length !== 32) {
        throw new Error('Not a valid UUID');
    }
    if (hex[12] !== '7') {
        throw new Error('Not a UUIDv7');
    }
    // the first 6 bytes are the timestamp, which means that we can read only the first 12 hex characters
    return parseInt(hex.substring(0, 12), 16);
};
exports.uuid7ToTimestampMs = uuid7ToTimestampMs;
//# sourceMappingURL=uuidv7.js.map