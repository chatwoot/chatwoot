import { __assign } from "tslib";
/**
 * Merge legacy settings and initialized Integration option overrides.
 *
 * This will merge any options that were passed from initialization into
 * overrides for settings that are returned by the Segment CDN.
 *
 * i.e. this allows for passing options directly into destinations from
 * the Analytics constructor.
 */
export function mergedOptions(settings, options) {
    var _a;
    var optionOverrides = Object.entries((_a = options.integrations) !== null && _a !== void 0 ? _a : {}).reduce(function (overrides, _a) {
        var _b, _c;
        var integration = _a[0], options = _a[1];
        if (typeof options === 'object') {
            return __assign(__assign({}, overrides), (_b = {}, _b[integration] = options, _b));
        }
        return __assign(__assign({}, overrides), (_c = {}, _c[integration] = {}, _c));
    }, {});
    return Object.entries(settings.integrations).reduce(function (integrationSettings, _a) {
        var _b;
        var integration = _a[0], settings = _a[1];
        return __assign(__assign({}, integrationSettings), (_b = {}, _b[integration] = __assign(__assign({}, settings), optionOverrides[integration]), _b));
    }, {});
}
//# sourceMappingURL=merged-options.js.map