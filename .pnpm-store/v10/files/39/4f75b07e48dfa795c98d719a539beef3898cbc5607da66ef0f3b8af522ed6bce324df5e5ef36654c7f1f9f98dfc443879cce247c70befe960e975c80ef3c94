import { __awaiter, __generator } from "tslib";
import { AnalyticsBrowser } from '.';
import { embeddedWriteKey } from '../lib/embedded-write-key';
function getWriteKey() {
    var _a;
    if (embeddedWriteKey()) {
        return embeddedWriteKey();
    }
    if (window.analytics._writeKey) {
        return window.analytics._writeKey;
    }
    var regex = /http.*\/analytics\.js\/v1\/([^/]*)(\/platform)?\/analytics.*/;
    var scripts = Array.prototype.slice.call(document.querySelectorAll('script'));
    var writeKey = undefined;
    for (var _i = 0, scripts_1 = scripts; _i < scripts_1.length; _i++) {
        var s = scripts_1[_i];
        var src = (_a = s.getAttribute('src')) !== null && _a !== void 0 ? _a : '';
        var result = regex.exec(src);
        if (result && result[1]) {
            writeKey = result[1];
            break;
        }
    }
    if (!writeKey && document.currentScript) {
        var script = document.currentScript;
        var src = script.src;
        var result = regex.exec(src);
        if (result && result[1]) {
            writeKey = result[1];
        }
    }
    return writeKey;
}
export function install() {
    var _a, _b;
    return __awaiter(this, void 0, void 0, function () {
        var writeKey, options, _c;
        return __generator(this, function (_d) {
            switch (_d.label) {
                case 0:
                    writeKey = getWriteKey();
                    options = (_b = (_a = window.analytics) === null || _a === void 0 ? void 0 : _a._loadOptions) !== null && _b !== void 0 ? _b : {};
                    if (!writeKey) {
                        console.error('Failed to load Write Key. Make sure to use the latest version of the Segment snippet, which can be found in your source settings.');
                        return [2 /*return*/];
                    }
                    _c = window;
                    return [4 /*yield*/, AnalyticsBrowser.standalone(writeKey, options)];
                case 1:
                    _c.analytics = (_d.sent());
                    return [2 /*return*/];
            }
        });
    });
}
//# sourceMappingURL=standalone-analytics.js.map