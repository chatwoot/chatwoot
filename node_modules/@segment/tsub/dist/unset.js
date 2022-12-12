"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.unset = void 0;
var dlv_1 = __importDefault(require("dlv"));
function unset(obj, prop) {
    if ((0, dlv_1.default)(obj, prop)) {
        var segs = prop.split('.');
        var last = segs.pop();
        while (segs.length && segs[segs.length - 1].slice(-1) === '\\') {
            last = segs.pop().slice(0, -1) + '.' + last;
        }
        while (segs.length)
            obj = obj[(prop = segs.shift())];
        return delete obj[last];
    }
    return true;
}
exports.unset = unset;
//# sourceMappingURL=unset.js.map