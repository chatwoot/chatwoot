"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var Store = /** @class */ (function () {
    function Store(rules) {
        this.rules = [];
        this.rules = rules || [];
    }
    Store.prototype.getRulesByDestinationName = function (destinationName) {
        var rules = [];
        for (var _i = 0, _a = this.rules; _i < _a.length; _i++) {
            var rule = _a[_i];
            // Rules with no destinationName are global (workspace || workspace::source)
            if (rule.destinationName === destinationName || rule.destinationName === undefined) {
                rules.push(rule);
            }
        }
        return rules;
    };
    return Store;
}());
exports.default = Store;
//# sourceMappingURL=store.js.map