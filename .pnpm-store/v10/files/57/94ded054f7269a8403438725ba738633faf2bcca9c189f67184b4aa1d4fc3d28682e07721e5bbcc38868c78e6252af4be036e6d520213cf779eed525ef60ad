"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.tagNodeResolvers = exports.tagResolvers = exports.STR = exports.NAN = exports.INFINITY = exports.FLOAT = exports.INT_BASE16 = exports.INT_BASE8 = exports.INT = exports.FALSE = exports.TRUE = exports.NULL = void 0;
const omap_1 = require("./omap");
const set_1 = require("./set");
exports.NULL = {
    // see https://yaml.org/spec/1.2/spec.html#id2803311
    tag: "tag:yaml.org,2002:null",
    testString(str) {
        return (!str || // empty
            // see https://yaml.org/spec/1.2/spec.html#id2805071
            str === "null" ||
            str === "Null" ||
            str === "NULL" ||
            str === "~");
    },
    resolveString() {
        return null;
    },
};
exports.TRUE = {
    // see https://yaml.org/spec/1.2/spec.html#id2803311
    tag: "tag:yaml.org,2002:bool",
    testString(str) {
        // see https://yaml.org/spec/1.2/spec.html#id2805071
        return str === "true" || str === "True" || str === "TRUE";
    },
    resolveString() {
        return true;
    },
};
exports.FALSE = {
    // see https://yaml.org/spec/1.2/spec.html#id2803311
    tag: "tag:yaml.org,2002:bool",
    testString(str) {
        // see https://yaml.org/spec/1.2/spec.html#id2805071
        return str === "false" || str === "False" || str === "FALSE";
    },
    resolveString() {
        return false;
    },
};
exports.INT = {
    // see https://yaml.org/spec/1.2/spec.html#id2803311
    tag: "tag:yaml.org,2002:int",
    testString(str) {
        // see https://yaml.org/spec/1.2/spec.html#id2805071
        return /^[+-]?\d+$/u.test(str);
    },
    resolveString(str) {
        return parseInt(str, 10);
    },
};
exports.INT_BASE8 = {
    // see https://yaml.org/spec/1.2/spec.html#id2803311
    tag: "tag:yaml.org,2002:int",
    testString(str) {
        // see https://yaml.org/spec/1.2/spec.html#id2805071
        return /^0o[0-7]+$/u.test(str);
    },
    resolveString(str) {
        return parseInt(str.slice(2), 8);
    },
};
exports.INT_BASE16 = {
    // see https://yaml.org/spec/1.2/spec.html#id2803311
    tag: "tag:yaml.org,2002:int",
    testString(str) {
        // see https://yaml.org/spec/1.2/spec.html#id2805071
        return /^0x[\dA-Fa-f]+$/u.test(str);
    },
    resolveString(str) {
        return parseInt(str.slice(2), 16);
    },
};
exports.FLOAT = {
    // see https://yaml.org/spec/1.2/spec.html#id2803311
    tag: "tag:yaml.org,2002:float",
    testString(str) {
        // see https://yaml.org/spec/1.2/spec.html#id2805071
        return /^[+-]?(?:\.\d+|\d+(?:\.\d*)?)(?:e[+-]?\d+)?$/iu.test(str);
    },
    resolveString(str) {
        return parseFloat(str);
    },
};
exports.INFINITY = {
    // see https://yaml.org/spec/1.2/spec.html#id2803311
    tag: "tag:yaml.org,2002:float",
    testString(str) {
        // see https://yaml.org/spec/1.2/spec.html#id2805071
        return /^[+-]?(?:\.inf|\.Inf|\.INF)$/u.test(str);
    },
    resolveString(str) {
        return str.startsWith("-") ? -Infinity : Infinity;
    },
};
exports.NAN = {
    // see https://yaml.org/spec/1.2/spec.html#id2803311
    tag: "tag:yaml.org,2002:float",
    testString(str) {
        // see https://yaml.org/spec/1.2/spec.html#id2805071
        return str === ".NaN" || str === ".nan" || str === ".NAN";
    },
    resolveString() {
        return NaN;
    },
};
exports.STR = {
    // see https://yaml.org/spec/1.2/spec.html#id2803311
    tag: "tag:yaml.org,2002:str",
    testString() {
        return true;
    },
    resolveString(str) {
        return str;
    },
};
exports.tagResolvers = [
    exports.NULL,
    exports.TRUE,
    exports.FALSE,
    exports.INT,
    exports.INT_BASE8,
    exports.INT_BASE16,
    exports.FLOAT,
    exports.INFINITY,
    exports.NAN,
    exports.STR,
];
exports.tagNodeResolvers = [omap_1.OMAP, set_1.SET];
