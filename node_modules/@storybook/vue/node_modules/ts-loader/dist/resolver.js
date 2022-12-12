"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.makeResolver = void 0;
// eslint-disable-next-line @typescript-eslint/no-var-requires
const node = require('enhanced-resolve/lib/node');
function makeResolver(options) {
    return node.create.sync(options.resolve);
}
exports.makeResolver = makeResolver;
//# sourceMappingURL=resolver.js.map