"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var parse_cdn_1 = require("../lib/parse-cdn");
var normalize_1 = require("../plugins/segmentio/normalize");
if (process.env.ASSET_PATH) {
    if (process.env.ASSET_PATH === '/dist/umd/') {
        // @ts-ignore
        __webpack_public_path__ = '/dist/umd/';
    }
    else {
        var cdn = (0, parse_cdn_1.getCDN)();
        (0, parse_cdn_1.setGlobalCDNUrl)(cdn); // preserving original behavior -- TODO: neccessary?
        // @ts-ignore
        __webpack_public_path__ = cdn + '/analytics-next/bundles/';
    }
}
(0, normalize_1.setVersionType)('web');
tslib_1.__exportStar(require("."), exports);
//# sourceMappingURL=browser-umd.js.map