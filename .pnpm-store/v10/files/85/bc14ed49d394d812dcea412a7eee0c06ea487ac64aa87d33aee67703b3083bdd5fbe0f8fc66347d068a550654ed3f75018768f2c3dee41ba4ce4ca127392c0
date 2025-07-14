"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.clone = void 0;
function clone(properties) {
    if (typeof properties !== 'object')
        return properties;
    if (Object.prototype.toString.call(properties) === '[object Object]') {
        var temp = {};
        for (var key in properties) {
            if (Object.prototype.hasOwnProperty.call(properties, key)) {
                temp[key] = clone(properties[key]);
            }
        }
        return temp;
    }
    else if (Array.isArray(properties)) {
        return properties.map(clone);
    }
    else {
        return properties;
    }
}
exports.clone = clone;
//# sourceMappingURL=clone.js.map