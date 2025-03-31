"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.tsubMiddleware = void 0;
var tslib_1 = require("tslib");
var tsub = tslib_1.__importStar(require("@segment/tsub"));
var tsubMiddleware = function (rules) {
    return function (_a) {
        var payload = _a.payload, integration = _a.integration, next = _a.next;
        var store = new tsub.Store(rules);
        var rulesToApply = store.getRulesByDestinationName(integration);
        rulesToApply.forEach(function (rule) {
            var matchers = rule.matchers, transformers = rule.transformers;
            for (var i = 0; i < matchers.length; i++) {
                if (tsub.matches(payload.obj, matchers[i])) {
                    payload.obj = tsub.transform(payload.obj, transformers[i]);
                    if (payload.obj === null) {
                        return next(null);
                    }
                }
            }
        });
        next(payload);
    };
};
exports.tsubMiddleware = tsubMiddleware;
//# sourceMappingURL=index.js.map