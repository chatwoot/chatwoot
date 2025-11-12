"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildParserUsingFlatConfig = void 0;
const synckit_1 = require("synckit");
const getSync = (0, synckit_1.createSyncFn)(require.resolve('./worker'));
function buildParserUsingFlatConfig(cwd) {
    return (filePath) => {
        return getSync(cwd, filePath);
    };
}
exports.buildParserUsingFlatConfig = buildParserUsingFlatConfig;
