"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.prepareStylesheet = void 0;
var logger_1 = require("../../utils/logger");
var logger = (0, logger_1.createLogger)('[Stylesheet Loader]');
var prepareStylesheet = function (document, innerText, posthog) {
    var _a;
    // Forcing the existence of `document` requires this function to be called in a browser environment
    var stylesheet = document.createElement('style');
    stylesheet.innerText = innerText;
    if ((_a = posthog === null || posthog === void 0 ? void 0 : posthog.config) === null || _a === void 0 ? void 0 : _a.prepare_external_dependency_stylesheet) {
        stylesheet = posthog.config.prepare_external_dependency_stylesheet(stylesheet);
    }
    if (!stylesheet) {
        logger.error('prepare_external_dependency_stylesheet returned null');
        return null;
    }
    return stylesheet;
};
exports.prepareStylesheet = prepareStylesheet;
//# sourceMappingURL=stylesheet-loader.js.map