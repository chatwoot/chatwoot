"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.toRegExp = void 0;
const RE_REGEXP_CHAR = /[\\^$.*+?()[\]{}|]/gu;
const RE_REGEXP_STR = /^\/(.+)\/(.*)$/u;
function toRegExp(str) {
    const parts = RE_REGEXP_STR.exec(str);
    if (parts) {
        return new RegExp(parts[1], parts[2]);
    }
    return new RegExp(`^${escape(str)}$`);
}
exports.toRegExp = toRegExp;
function escape(str) {
    return str && str.replace(RE_REGEXP_CHAR, '\\$&');
}
