/*! For license information please see uuidv7.js.LICENSE.txt */
"use strict";
var __webpack_require__ = {};
(()=>{
    __webpack_require__.d = (exports1, definition)=>{
        for(var key in definition)if (__webpack_require__.o(definition, key) && !__webpack_require__.o(exports1, key)) Object.defineProperty(exports1, key, {
            enumerable: true,
            get: definition[key]
        });
    };
})();
(()=>{
    __webpack_require__.o = (obj, prop)=>Object.prototype.hasOwnProperty.call(obj, prop);
})();
(()=>{
    __webpack_require__.r = (exports1)=>{
        if ('undefined' != typeof Symbol && Symbol.toStringTag) Object.defineProperty(exports1, Symbol.toStringTag, {
            value: 'Module'
        });
        Object.defineProperty(exports1, '__esModule', {
            value: true
        });
    };
})();
var __webpack_exports__ = {};
__webpack_require__.r(__webpack_exports__);
__webpack_require__.d(__webpack_exports__, {
    UUID: ()=>UUID,
    V7Generator: ()=>V7Generator,
    uuidv4: ()=>uuidv4,
    uuidv4obj: ()=>uuidv4obj,
    uuidv7: ()=>uuidv7,
    uuidv7obj: ()=>uuidv7obj
});
/**
 * uuidv7: An experimental implementation of the proposed UUID Version 7
 *
 * @license Apache-2.0
 * @copyright 2021-2023 LiosK
 * @packageDocumentation
 */ const DIGITS = "0123456789abcdef";
class UUID {
    static ofInner(bytes) {
        if (16 === bytes.length) return new UUID(bytes);
        throw new TypeError("not 128-bit length");
    }
    static fromFieldsV7(unixTsMs, randA, randBHi, randBLo) {
        if (!Number.isInteger(unixTsMs) || !Number.isInteger(randA) || !Number.isInteger(randBHi) || !Number.isInteger(randBLo) || unixTsMs < 0 || randA < 0 || randBHi < 0 || randBLo < 0 || unixTsMs > 0xffffffffffff || randA > 0xfff || randBHi > 0x3fffffff || randBLo > 0xffffffff) throw new RangeError("invalid field value");
        const bytes = new Uint8Array(16);
        bytes[0] = unixTsMs / 2 ** 40;
        bytes[1] = unixTsMs / 2 ** 32;
        bytes[2] = unixTsMs / 2 ** 24;
        bytes[3] = unixTsMs / 2 ** 16;
        bytes[4] = unixTsMs / 256;
        bytes[5] = unixTsMs;
        bytes[6] = 0x70 | randA >>> 8;
        bytes[7] = randA;
        bytes[8] = 0x80 | randBHi >>> 24;
        bytes[9] = randBHi >>> 16;
        bytes[10] = randBHi >>> 8;
        bytes[11] = randBHi;
        bytes[12] = randBLo >>> 24;
        bytes[13] = randBLo >>> 16;
        bytes[14] = randBLo >>> 8;
        bytes[15] = randBLo;
        return new UUID(bytes);
    }
    static parse(uuid) {
        let hex;
        switch(uuid.length){
            case 32:
                var _exec;
                hex = null == (_exec = /^[0-9a-f]{32}$/i.exec(uuid)) ? void 0 : _exec[0];
                break;
            case 36:
                var _exec1;
                hex = null == (_exec1 = /^([0-9a-f]{8})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{12})$/i.exec(uuid)) ? void 0 : _exec1.slice(1, 6).join("");
                break;
            case 38:
                var _exec2;
                hex = null == (_exec2 = /^\{([0-9a-f]{8})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{12})\}$/i.exec(uuid)) ? void 0 : _exec2.slice(1, 6).join("");
                break;
            case 45:
                var _exec3;
                hex = null == (_exec3 = /^urn:uuid:([0-9a-f]{8})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{12})$/i.exec(uuid)) ? void 0 : _exec3.slice(1, 6).join("");
                break;
            default:
                break;
        }
        if (hex) {
            const inner = new Uint8Array(16);
            for(let i = 0; i < 16; i += 4){
                const n = parseInt(hex.substring(2 * i, 2 * i + 8), 16);
                inner[i + 0] = n >>> 24;
                inner[i + 1] = n >>> 16;
                inner[i + 2] = n >>> 8;
                inner[i + 3] = n;
            }
            return new UUID(inner);
        }
        throw new SyntaxError("could not parse UUID string");
    }
    toString() {
        let text = "";
        for(let i = 0; i < this.bytes.length; i++){
            text += DIGITS.charAt(this.bytes[i] >>> 4);
            text += DIGITS.charAt(0xf & this.bytes[i]);
            if (3 === i || 5 === i || 7 === i || 9 === i) text += "-";
        }
        return text;
    }
    toHex() {
        let text = "";
        for(let i = 0; i < this.bytes.length; i++){
            text += DIGITS.charAt(this.bytes[i] >>> 4);
            text += DIGITS.charAt(0xf & this.bytes[i]);
        }
        return text;
    }
    toJSON() {
        return this.toString();
    }
    getVariant() {
        const n = this.bytes[8] >>> 4;
        if (n < 0) throw new Error("unreachable");
        if (n <= 7) return this.bytes.every((e)=>0 === e) ? "NIL" : "VAR_0";
        if (n <= 11) return "VAR_10";
        if (n <= 13) return "VAR_110";
        if (n <= 15) return this.bytes.every((e)=>0xff === e) ? "MAX" : "VAR_RESERVED";
        else throw new Error("unreachable");
    }
    getVersion() {
        return "VAR_10" === this.getVariant() ? this.bytes[6] >>> 4 : void 0;
    }
    clone() {
        return new UUID(this.bytes.slice(0));
    }
    equals(other) {
        return 0 === this.compareTo(other);
    }
    compareTo(other) {
        for(let i = 0; i < 16; i++){
            const diff = this.bytes[i] - other.bytes[i];
            if (0 !== diff) return Math.sign(diff);
        }
        return 0;
    }
    constructor(bytes){
        this.bytes = bytes;
    }
}
class V7Generator {
    generate() {
        return this.generateOrResetCore(Date.now(), 10000);
    }
    generateOrAbort() {
        return this.generateOrAbortCore(Date.now(), 10000);
    }
    generateOrResetCore(unixTsMs, rollbackAllowance) {
        let value = this.generateOrAbortCore(unixTsMs, rollbackAllowance);
        if (void 0 === value) {
            this.timestamp = 0;
            value = this.generateOrAbortCore(unixTsMs, rollbackAllowance);
        }
        return value;
    }
    generateOrAbortCore(unixTsMs, rollbackAllowance) {
        const MAX_COUNTER = 0x3ffffffffff;
        if (!Number.isInteger(unixTsMs) || unixTsMs < 1 || unixTsMs > 0xffffffffffff) throw new RangeError("`unixTsMs` must be a 48-bit positive integer");
        if (rollbackAllowance < 0 || rollbackAllowance > 0xffffffffffff) throw new RangeError("`rollbackAllowance` out of reasonable range");
        if (unixTsMs > this.timestamp) {
            this.timestamp = unixTsMs;
            this.resetCounter();
        } else {
            if (!(unixTsMs + rollbackAllowance >= this.timestamp)) return;
            this.counter++;
            if (this.counter > MAX_COUNTER) {
                this.timestamp++;
                this.resetCounter();
            }
        }
        return UUID.fromFieldsV7(this.timestamp, Math.trunc(this.counter / 2 ** 30), this.counter & 2 ** 30 - 1, this.random.nextUint32());
    }
    resetCounter() {
        this.counter = 0x400 * this.random.nextUint32() + (0x3ff & this.random.nextUint32());
    }
    generateV4() {
        const bytes = new Uint8Array(Uint32Array.of(this.random.nextUint32(), this.random.nextUint32(), this.random.nextUint32(), this.random.nextUint32()).buffer);
        bytes[6] = 0x40 | bytes[6] >>> 4;
        bytes[8] = 0x80 | bytes[8] >>> 2;
        return UUID.ofInner(bytes);
    }
    constructor(randomNumberGenerator){
        this.timestamp = 0;
        this.counter = 0;
        this.random = null != randomNumberGenerator ? randomNumberGenerator : getDefaultRandom();
    }
}
const getDefaultRandom = ()=>({
        nextUint32: ()=>0x10000 * Math.trunc(0x10000 * Math.random()) + Math.trunc(0x10000 * Math.random())
    });
let defaultGenerator;
const uuidv7 = ()=>uuidv7obj().toString();
const uuidv7obj = ()=>(defaultGenerator || (defaultGenerator = new V7Generator())).generate();
const uuidv4 = ()=>uuidv4obj().toString();
const uuidv4obj = ()=>(defaultGenerator || (defaultGenerator = new V7Generator())).generateV4();
exports.UUID = __webpack_exports__.UUID;
exports.V7Generator = __webpack_exports__.V7Generator;
exports.uuidv4 = __webpack_exports__.uuidv4;
exports.uuidv4obj = __webpack_exports__.uuidv4obj;
exports.uuidv7 = __webpack_exports__.uuidv7;
exports.uuidv7obj = __webpack_exports__.uuidv7obj;
for(var __webpack_i__ in __webpack_exports__)if (-1 === [
    "UUID",
    "V7Generator",
    "uuidv4",
    "uuidv4obj",
    "uuidv7",
    "uuidv7obj"
].indexOf(__webpack_i__)) exports[__webpack_i__] = __webpack_exports__[__webpack_i__];
Object.defineProperty(exports, '__esModule', {
    value: true
});
