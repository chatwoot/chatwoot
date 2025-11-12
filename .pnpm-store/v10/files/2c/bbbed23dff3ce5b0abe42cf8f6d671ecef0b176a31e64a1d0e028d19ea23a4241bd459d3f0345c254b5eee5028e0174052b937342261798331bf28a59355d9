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
    createImperativePromise: ()=>createImperativePromise,
    delay: ()=>delay,
    parseBody: ()=>parseBody,
    wait: ()=>wait,
    waitForPromises: ()=>waitForPromises
});
const wait = async (t)=>{
    await new Promise((r)=>setTimeout(r, t));
};
const waitForPromises = async ()=>{
    await new Promise((resolve)=>{
        jest.useRealTimers();
        setTimeout(resolve, 10);
        jest.useFakeTimers();
    });
};
const parseBody = (mockCall)=>{
    const options = mockCall[1];
    expect(options.method).toBe('POST');
    return JSON.parse(options.body || '');
};
const createImperativePromise = ()=>{
    let resolve;
    const promise = new Promise((r)=>{
        resolve = r;
    });
    return [
        promise,
        (val)=>null == resolve ? void 0 : resolve(val)
    ];
};
const delay = (ms)=>new Promise((resolve)=>{
        setTimeout(resolve, ms);
    });
exports.createImperativePromise = __webpack_exports__.createImperativePromise;
exports.delay = __webpack_exports__.delay;
exports.parseBody = __webpack_exports__.parseBody;
exports.wait = __webpack_exports__.wait;
exports.waitForPromises = __webpack_exports__.waitForPromises;
for(var __webpack_i__ in __webpack_exports__)if (-1 === [
    "createImperativePromise",
    "delay",
    "parseBody",
    "wait",
    "waitForPromises"
].indexOf(__webpack_i__)) exports[__webpack_i__] = __webpack_exports__[__webpack_i__];
Object.defineProperty(exports, '__esModule', {
    value: true
});
