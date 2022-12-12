import { __read, __spread } from "tslib";
import { addGlobalEventProcessor, getCurrentHub } from '@sentry/core';
import { isInstanceOf } from '@sentry/utils';
import { exceptionFromError } from '../eventbuilder';
var DEFAULT_KEY = 'cause';
var DEFAULT_LIMIT = 5;
/** Adds SDK info to an event. */
var LinkedErrors = /** @class */ (function () {
    /**
     * @inheritDoc
     */
    function LinkedErrors(options) {
        if (options === void 0) { options = {}; }
        /**
         * @inheritDoc
         */
        this.name = LinkedErrors.id;
        this._key = options.key || DEFAULT_KEY;
        this._limit = options.limit || DEFAULT_LIMIT;
    }
    /**
     * @inheritDoc
     */
    LinkedErrors.prototype.setupOnce = function () {
        addGlobalEventProcessor(function (event, hint) {
            var self = getCurrentHub().getIntegration(LinkedErrors);
            return self ? _handler(self._key, self._limit, event, hint) : event;
        });
    };
    /**
     * @inheritDoc
     */
    LinkedErrors.id = 'LinkedErrors';
    return LinkedErrors;
}());
export { LinkedErrors };
/**
 * @inheritDoc
 */
export function _handler(key, limit, event, hint) {
    if (!event.exception || !event.exception.values || !hint || !isInstanceOf(hint.originalException, Error)) {
        return event;
    }
    var linkedErrors = _walkErrorTree(limit, hint.originalException, key);
    event.exception.values = __spread(linkedErrors, event.exception.values);
    return event;
}
/**
 * JSDOC
 */
export function _walkErrorTree(limit, error, key, stack) {
    if (stack === void 0) { stack = []; }
    if (!isInstanceOf(error[key], Error) || stack.length + 1 >= limit) {
        return stack;
    }
    var exception = exceptionFromError(error[key]);
    return _walkErrorTree(limit, error[key], key, __spread([exception], stack));
}
//# sourceMappingURL=linkederrors.js.map