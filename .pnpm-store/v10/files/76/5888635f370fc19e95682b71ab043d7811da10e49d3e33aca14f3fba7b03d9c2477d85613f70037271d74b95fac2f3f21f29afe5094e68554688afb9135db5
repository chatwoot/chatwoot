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
    gzipCompress: ()=>gzipCompress,
    isGzipSupported: ()=>isGzipSupported
});
function isGzipSupported() {
    return 'CompressionStream' in globalThis;
}
async function gzipCompress(input) {
    let isDebug = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : true;
    try {
        const dataStream = new Blob([
            input
        ], {
            type: 'text/plain'
        }).stream();
        const compressedStream = dataStream.pipeThrough(new CompressionStream('gzip'));
        return await new Response(compressedStream).blob();
    } catch (error) {
        if (isDebug) console.error('Failed to gzip compress data', error);
        return null;
    }
}
exports.gzipCompress = __webpack_exports__.gzipCompress;
exports.isGzipSupported = __webpack_exports__.isGzipSupported;
for(var __webpack_i__ in __webpack_exports__)if (-1 === [
    "gzipCompress",
    "isGzipSupported"
].indexOf(__webpack_i__)) exports[__webpack_i__] = __webpack_exports__[__webpack_i__];
Object.defineProperty(exports, '__esModule', {
    value: true
});
