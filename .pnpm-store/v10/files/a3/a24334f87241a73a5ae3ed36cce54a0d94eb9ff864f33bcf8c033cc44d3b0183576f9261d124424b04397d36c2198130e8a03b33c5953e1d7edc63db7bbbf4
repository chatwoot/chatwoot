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
    SimpleEventEmitter: ()=>SimpleEventEmitter
});
class SimpleEventEmitter {
    on(event, listener) {
        if (!this.events[event]) this.events[event] = [];
        this.events[event].push(listener);
        return ()=>{
            this.events[event] = this.events[event].filter((x)=>x !== listener);
        };
    }
    emit(event, payload) {
        for (const listener of this.events[event] || [])listener(payload);
        for (const listener of this.events['*'] || [])listener(event, payload);
    }
    constructor(){
        this.events = {};
        this.events = {};
    }
}
exports.SimpleEventEmitter = __webpack_exports__.SimpleEventEmitter;
for(var __webpack_i__ in __webpack_exports__)if (-1 === [
    "SimpleEventEmitter"
].indexOf(__webpack_i__)) exports[__webpack_i__] = __webpack_exports__[__webpack_i__];
Object.defineProperty(exports, '__esModule', {
    value: true
});
