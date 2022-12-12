"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var CodeframeFormatter_1 = require("./CodeframeFormatter");
var DefaultFormatter_1 = require("./DefaultFormatter");
function createFormatter(type, options) {
    if (typeof type === 'function') {
        return type;
    }
    switch (type) {
        case 'codeframe':
            return CodeframeFormatter_1.createCodeframeFormatter(options);
        case 'default':
        case undefined:
            return DefaultFormatter_1.createDefaultFormatter();
        default:
            throw new Error('Unknown "' +
                type +
                '" formatter. Available types are: default, codeframe.');
    }
}
exports.createFormatter = createFormatter;
//# sourceMappingURL=FormatterFactory.js.map