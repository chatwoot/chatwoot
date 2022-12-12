"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.shouldPolyfill = void 0;
function shouldPolyfill() {
    var browserVersionCompatList = {
        Firefox: 46,
        Edge: 13,
    };
    // Unfortunately IE doesn't follow the same pattern as other browsers, so we
    // need to check `isIE11` differently.
    // @ts-expect-error
    var isIE11 = !!window.MSInputMethodContext && !!document.documentMode;
    var userAgent = navigator.userAgent.split(' ');
    var _a = userAgent[userAgent.length - 1].split('/'), browser = _a[0], version = _a[1];
    return (isIE11 ||
        (browserVersionCompatList[browser] !== undefined &&
            browserVersionCompatList[browser] >= parseInt(version)));
}
exports.shouldPolyfill = shouldPolyfill;
// appName = Netscape IE / Edge
// edge 13 Edge/13... same as FF
//# sourceMappingURL=browser-polyfill.js.map