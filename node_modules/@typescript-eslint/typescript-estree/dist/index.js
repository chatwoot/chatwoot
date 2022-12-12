"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.version = exports.visitorKeys = exports.createProgram = exports.clearCaches = exports.simpleTraverse = exports.clearProgramCache = exports.parseWithNodeMaps = exports.parseAndGenerateServices = exports.parse = void 0;
var parser_1 = require("./parser");
Object.defineProperty(exports, "parse", { enumerable: true, get: function () { return parser_1.parse; } });
Object.defineProperty(exports, "parseAndGenerateServices", { enumerable: true, get: function () { return parser_1.parseAndGenerateServices; } });
Object.defineProperty(exports, "parseWithNodeMaps", { enumerable: true, get: function () { return parser_1.parseWithNodeMaps; } });
Object.defineProperty(exports, "clearProgramCache", { enumerable: true, get: function () { return parser_1.clearProgramCache; } });
var simple_traverse_1 = require("./simple-traverse");
Object.defineProperty(exports, "simpleTraverse", { enumerable: true, get: function () { return simple_traverse_1.simpleTraverse; } });
__exportStar(require("./ts-estree"), exports);
var createWatchProgram_1 = require("./create-program/createWatchProgram");
Object.defineProperty(exports, "clearCaches", { enumerable: true, get: function () { return createWatchProgram_1.clearWatchCaches; } });
var useProvidedPrograms_1 = require("./create-program/useProvidedPrograms");
Object.defineProperty(exports, "createProgram", { enumerable: true, get: function () { return useProvidedPrograms_1.createProgramFromConfigFile; } });
__exportStar(require("./create-program/getScriptKind"), exports);
// re-export for backwards-compat
var visitor_keys_1 = require("@typescript-eslint/visitor-keys");
Object.defineProperty(exports, "visitorKeys", { enumerable: true, get: function () { return visitor_keys_1.visitorKeys; } });
// note - cannot migrate this to an import statement because it will make TSC copy the package.json to the dist folder
// eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access
exports.version = require('../package.json').version;
//# sourceMappingURL=index.js.map