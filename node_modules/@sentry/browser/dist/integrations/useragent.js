Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var core_1 = require("@sentry/core");
var utils_1 = require("@sentry/utils");
var global = utils_1.getGlobalObject();
/** UserAgent */
var UserAgent = /** @class */ (function () {
    function UserAgent() {
        /**
         * @inheritDoc
         */
        this.name = UserAgent.id;
    }
    /**
     * @inheritDoc
     */
    UserAgent.prototype.setupOnce = function () {
        core_1.addGlobalEventProcessor(function (event) {
            if (core_1.getCurrentHub().getIntegration(UserAgent)) {
                // if none of the information we want exists, don't bother
                if (!global.navigator && !global.location && !global.document) {
                    return event;
                }
                // grab as much info as exists and add it to the event
                var url = (event.request && event.request.url) || (global.location && global.location.href);
                var referrer = (global.document || {}).referrer;
                var userAgent = (global.navigator || {}).userAgent;
                var headers = tslib_1.__assign(tslib_1.__assign(tslib_1.__assign({}, (event.request && event.request.headers)), (referrer && { Referer: referrer })), (userAgent && { 'User-Agent': userAgent }));
                var request = tslib_1.__assign(tslib_1.__assign({}, (url && { url: url })), { headers: headers });
                return tslib_1.__assign(tslib_1.__assign({}, event), { request: request });
            }
            return event;
        });
    };
    /**
     * @inheritDoc
     */
    UserAgent.id = 'UserAgent';
    return UserAgent;
}());
exports.UserAgent = UserAgent;
//# sourceMappingURL=useragent.js.map