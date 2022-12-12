"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var _setImmediate;
if (typeof setImmediate === 'function')
    _setImmediate = setImmediate.bind(global);
else
    _setImmediate = setTimeout.bind(global);
exports.default = _setImmediate;
