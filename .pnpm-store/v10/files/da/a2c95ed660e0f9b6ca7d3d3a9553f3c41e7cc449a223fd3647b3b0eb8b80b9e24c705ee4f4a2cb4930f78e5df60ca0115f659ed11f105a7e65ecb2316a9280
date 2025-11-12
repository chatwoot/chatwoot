"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parsePath = exports.joinPath = void 0;
const core_base_1 = require("@intlify/core-base");
function joinPath(...paths) {
    let result = '';
    for (const p of paths) {
        if (typeof p === 'number') {
            result += `[${p}]`;
        }
        else if (/^[^\s,.[\]]+$/iu.test(p)) {
            result = result ? `${result}.${p}` : p;
        }
        else if (/^(?:0|[1-9]\d*)*$/iu.test(p)) {
            result += `[${p}]`;
        }
        else {
            result += `[${JSON.stringify(p)}]`;
        }
    }
    return result;
}
exports.joinPath = joinPath;
function parsePath(path) {
    return (0, core_base_1.parse)(path) || [path];
}
exports.parsePath = parsePath;
