import { __extends } from "tslib";
import { CoreContext, ContextCancelation, } from '@segment/analytics-core';
import { Stats } from '../stats';
var Context = /** @class */ (function (_super) {
    __extends(Context, _super);
    function Context(event, id) {
        return _super.call(this, event, id, new Stats()) || this;
    }
    Context.system = function () {
        return new this({ type: 'track', event: 'system' });
    };
    return Context;
}(CoreContext));
export { Context };
export { ContextCancelation };
//# sourceMappingURL=index.js.map