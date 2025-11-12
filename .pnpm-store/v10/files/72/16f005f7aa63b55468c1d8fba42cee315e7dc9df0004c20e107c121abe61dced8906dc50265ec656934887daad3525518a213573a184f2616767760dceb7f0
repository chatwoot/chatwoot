"use strict";
var __webpack_modules__ = {
    "./bucketed-rate-limiter": function(module) {
        module.exports = require("./bucketed-rate-limiter.js");
    },
    "./number-utils": function(module) {
        module.exports = require("./number-utils.js");
    },
    "./string-utils": function(module) {
        module.exports = require("./string-utils.js");
    },
    "./type-utils": function(module) {
        module.exports = require("./type-utils.js");
    }
};
var __webpack_module_cache__ = {};
function __webpack_require__(moduleId) {
    var cachedModule = __webpack_module_cache__[moduleId];
    if (void 0 !== cachedModule) return cachedModule.exports;
    var module = __webpack_module_cache__[moduleId] = {
        exports: {}
    };
    __webpack_modules__[moduleId](module, module.exports, __webpack_require__);
    return module.exports;
}
(()=>{
    __webpack_require__.n = (module)=>{
        var getter = module && module.__esModule ? ()=>module['default'] : ()=>module;
        __webpack_require__.d(getter, {
            a: getter
        });
        return getter;
    };
})();
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
(()=>{
    __webpack_require__.r(__webpack_exports__);
    __webpack_require__.d(__webpack_exports__, {
        STRING_FORMAT: ()=>STRING_FORMAT,
        allSettled: ()=>allSettled,
        assert: ()=>assert,
        currentISOTime: ()=>currentISOTime,
        currentTimestamp: ()=>currentTimestamp,
        getFetch: ()=>getFetch,
        isError: ()=>isError,
        isPromise: ()=>isPromise,
        removeTrailingSlash: ()=>removeTrailingSlash,
        retriable: ()=>retriable,
        safeSetTimeout: ()=>safeSetTimeout
    });
    var _bucketed_rate_limiter__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__("./bucketed-rate-limiter");
    var __WEBPACK_REEXPORT_OBJECT__ = {};
    for(var __WEBPACK_IMPORT_KEY__ in _bucketed_rate_limiter__WEBPACK_IMPORTED_MODULE_0__)if ([
        "removeTrailingSlash",
        "retriable",
        "default",
        "currentISOTime",
        "currentTimestamp",
        "STRING_FORMAT",
        "isError",
        "safeSetTimeout",
        "getFetch",
        "isPromise",
        "assert",
        "allSettled"
    ].indexOf(__WEBPACK_IMPORT_KEY__) < 0) __WEBPACK_REEXPORT_OBJECT__[__WEBPACK_IMPORT_KEY__] = (function(key) {
        return _bucketed_rate_limiter__WEBPACK_IMPORTED_MODULE_0__[key];
    }).bind(0, __WEBPACK_IMPORT_KEY__);
    __webpack_require__.d(__webpack_exports__, __WEBPACK_REEXPORT_OBJECT__);
    var _number_utils__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__("./number-utils");
    var __WEBPACK_REEXPORT_OBJECT__ = {};
    for(var __WEBPACK_IMPORT_KEY__ in _number_utils__WEBPACK_IMPORTED_MODULE_1__)if ([
        "removeTrailingSlash",
        "retriable",
        "default",
        "currentISOTime",
        "currentTimestamp",
        "STRING_FORMAT",
        "isError",
        "safeSetTimeout",
        "getFetch",
        "isPromise",
        "assert",
        "allSettled"
    ].indexOf(__WEBPACK_IMPORT_KEY__) < 0) __WEBPACK_REEXPORT_OBJECT__[__WEBPACK_IMPORT_KEY__] = (function(key) {
        return _number_utils__WEBPACK_IMPORTED_MODULE_1__[key];
    }).bind(0, __WEBPACK_IMPORT_KEY__);
    __webpack_require__.d(__webpack_exports__, __WEBPACK_REEXPORT_OBJECT__);
    var _string_utils__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__("./string-utils");
    var __WEBPACK_REEXPORT_OBJECT__ = {};
    for(var __WEBPACK_IMPORT_KEY__ in _string_utils__WEBPACK_IMPORTED_MODULE_2__)if ([
        "removeTrailingSlash",
        "retriable",
        "default",
        "currentISOTime",
        "currentTimestamp",
        "STRING_FORMAT",
        "isError",
        "safeSetTimeout",
        "getFetch",
        "isPromise",
        "assert",
        "allSettled"
    ].indexOf(__WEBPACK_IMPORT_KEY__) < 0) __WEBPACK_REEXPORT_OBJECT__[__WEBPACK_IMPORT_KEY__] = (function(key) {
        return _string_utils__WEBPACK_IMPORTED_MODULE_2__[key];
    }).bind(0, __WEBPACK_IMPORT_KEY__);
    __webpack_require__.d(__webpack_exports__, __WEBPACK_REEXPORT_OBJECT__);
    var _type_utils__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__("./type-utils");
    var __WEBPACK_REEXPORT_OBJECT__ = {};
    for(var __WEBPACK_IMPORT_KEY__ in _type_utils__WEBPACK_IMPORTED_MODULE_3__)if ([
        "removeTrailingSlash",
        "retriable",
        "default",
        "currentISOTime",
        "currentTimestamp",
        "STRING_FORMAT",
        "isError",
        "safeSetTimeout",
        "getFetch",
        "isPromise",
        "assert",
        "allSettled"
    ].indexOf(__WEBPACK_IMPORT_KEY__) < 0) __WEBPACK_REEXPORT_OBJECT__[__WEBPACK_IMPORT_KEY__] = (function(key) {
        return _type_utils__WEBPACK_IMPORTED_MODULE_3__[key];
    }).bind(0, __WEBPACK_IMPORT_KEY__);
    __webpack_require__.d(__webpack_exports__, __WEBPACK_REEXPORT_OBJECT__);
    const STRING_FORMAT = 'utf8';
    function assert(truthyValue, message) {
        if (!truthyValue || 'string' != typeof truthyValue || isEmpty(truthyValue)) throw new Error(message);
    }
    function isEmpty(truthyValue) {
        if (0 === truthyValue.trim().length) return true;
        return false;
    }
    function removeTrailingSlash(url) {
        return null == url ? void 0 : url.replace(/\/+$/, '');
    }
    async function retriable(fn, props) {
        let lastError = null;
        for(let i = 0; i < props.retryCount + 1; i++){
            if (i > 0) await new Promise((r)=>setTimeout(r, props.retryDelay));
            try {
                const res = await fn();
                return res;
            } catch (e) {
                lastError = e;
                if (!props.retryCheck(e)) throw e;
            }
        }
        throw lastError;
    }
    function currentTimestamp() {
        return new Date().getTime();
    }
    function currentISOTime() {
        return new Date().toISOString();
    }
    function safeSetTimeout(fn, timeout) {
        const t = setTimeout(fn, timeout);
        (null == t ? void 0 : t.unref) && (null == t || t.unref());
        return t;
    }
    const isPromise = (obj)=>obj && 'function' == typeof obj.then;
    const isError = (x)=>x instanceof Error;
    function getFetch() {
        return 'undefined' != typeof fetch ? fetch : void 0 !== globalThis.fetch ? globalThis.fetch : void 0;
    }
    function allSettled(promises) {
        return Promise.all(promises.map((p)=>(null != p ? p : Promise.resolve()).then((value)=>({
                    status: 'fulfilled',
                    value
                }), (reason)=>({
                    status: 'rejected',
                    reason
                }))));
    }
})();
exports.STRING_FORMAT = __webpack_exports__.STRING_FORMAT;
exports.allSettled = __webpack_exports__.allSettled;
exports.assert = __webpack_exports__.assert;
exports.currentISOTime = __webpack_exports__.currentISOTime;
exports.currentTimestamp = __webpack_exports__.currentTimestamp;
exports.getFetch = __webpack_exports__.getFetch;
exports.isError = __webpack_exports__.isError;
exports.isPromise = __webpack_exports__.isPromise;
exports.removeTrailingSlash = __webpack_exports__.removeTrailingSlash;
exports.retriable = __webpack_exports__.retriable;
exports.safeSetTimeout = __webpack_exports__.safeSetTimeout;
for(var __webpack_i__ in __webpack_exports__)if (-1 === [
    "STRING_FORMAT",
    "allSettled",
    "assert",
    "currentISOTime",
    "currentTimestamp",
    "getFetch",
    "isError",
    "isPromise",
    "removeTrailingSlash",
    "retriable",
    "safeSetTimeout"
].indexOf(__webpack_i__)) exports[__webpack_i__] = __webpack_exports__[__webpack_i__];
Object.defineProperty(exports, '__esModule', {
    value: true
});
