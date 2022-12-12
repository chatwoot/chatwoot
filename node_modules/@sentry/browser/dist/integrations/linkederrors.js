Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var core_1 = require("@sentry/core");
var utils_1 = require("@sentry/utils");
var eventbuilder_1 = require("../eventbuilder");
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
        core_1.addGlobalEventProcessor(function (event, hint) {
            var self = core_1.getCurrentHub().getIntegration(LinkedErrors);
            return self ? _handler(self._key, self._limit, event, hint) : event;
        });
    };
    /**
     * @inheritDoc
     */
    LinkedErrors.id = 'LinkedErrors';
    return LinkedErrors;
}());
exports.LinkedErrors = LinkedErrors;
/**
 * @inheritDoc
 */
function _handler(key, limit, event, hint) {
    if (!event.exception || !event.exception.values || !hint || !utils_1.isInstanceOf(hint.originalException, Error)) {
        return event;
    }
    var linkedErrors = _walkErrorTree(limit, hint.originalException, key);
    event.exception.values = tslib_1.__spread(linkedErrors, event.exception.values);
    return event;
}
exports._handler = _handler;
/**
 * JSDOC
 */
function _walkErrorTree(limit, error, key, stack) {
    if (stack === void 0) { stack = []; }
    if (!utils_1.isInstanceOf(error[key], Error) || stack.length + 1 >= limit) {
        return stack;
    }
    var exception = eventbuilder_1.exceptionFromError(error[key]);
    return _walkErrorTree(limit, error[key], key, tslib_1.__spread([exception], stack));
}
exports._walkErrorTree = _walkErrorTree;
//# sourceMappingURL=linkederrors.js.map