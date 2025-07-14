import * as tsub from '@segment/tsub';
export var tsubMiddleware = function (rules) {
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
//# sourceMappingURL=index.js.map