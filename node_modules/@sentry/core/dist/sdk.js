Object.defineProperty(exports, "__esModule", { value: true });
var hub_1 = require("@sentry/hub");
var utils_1 = require("@sentry/utils");
var flags_1 = require("./flags");
/**
 * Internal function to create a new SDK client instance. The client is
 * installed and then bound to the current scope.
 *
 * @param clientClass The client class to instantiate.
 * @param options Options to pass to the client.
 */
function initAndBind(clientClass, options) {
    if (options.debug === true) {
        if (flags_1.IS_DEBUG_BUILD) {
            utils_1.logger.enable();
        }
        else {
            // use `console.warn` rather than `logger.warn` since by non-debug bundles have all `logger.x` statements stripped
            // eslint-disable-next-line no-console
            console.warn('[Sentry] Cannot initialize SDK with `debug` option using a non-debug bundle.');
        }
    }
    var hub = hub_1.getCurrentHub();
    var scope = hub.getScope();
    if (scope) {
        scope.update(options.initialScope);
    }
    var client = new clientClass(options);
    hub.bindClient(client);
}
exports.initAndBind = initAndBind;
//# sourceMappingURL=sdk.js.map