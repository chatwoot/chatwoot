"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var globals_1 = require("../utils/globals");
var logger_1 = require("../utils/logger");
var logger = (0, logger_1.createLogger)('[PostHog Crisp Chat]');
var reportedSessionIds = new Set();
var sessionIdListenerUnsubscribe = undefined;
globals_1.assignableWindow.__PosthogExtensions__ = globals_1.assignableWindow.__PosthogExtensions__ || {};
globals_1.assignableWindow.__PosthogExtensions__.integrations = globals_1.assignableWindow.__PosthogExtensions__.integrations || {};
globals_1.assignableWindow.__PosthogExtensions__.integrations.crispChat = {
    start: function (posthog) {
        var _a;
        if (!((_a = posthog.config.integrations) === null || _a === void 0 ? void 0 : _a.crispChat)) {
            return;
        }
        var crispChat = globals_1.assignableWindow.$crisp;
        if (!crispChat) {
            logger.warn('Crisp Chat not found while initializing the integration');
            return;
        }
        var updateCrispChat = function () {
            var replayUrl = posthog.get_session_replay_url();
            var personUrl = posthog.requestRouter.endpointFor('ui', "/project/".concat(posthog.config.token, "/person/").concat(posthog.get_distinct_id()));
            crispChat.push([
                'set',
                'session:data',
                [
                    [
                        ['posthogSessionURL', replayUrl],
                        ['posthogPersonURL', personUrl],
                    ],
                ],
            ]);
        };
        // this is called immediately if there's a session id
        // and then again whenever the session id changes
        sessionIdListenerUnsubscribe = posthog.onSessionId(function (sessionId) {
            if (!reportedSessionIds.has(sessionId)) {
                updateCrispChat();
                reportedSessionIds.add(sessionId);
            }
        });
        logger.info('integration started');
    },
    stop: function () {
        sessionIdListenerUnsubscribe === null || sessionIdListenerUnsubscribe === void 0 ? void 0 : sessionIdListenerUnsubscribe();
        sessionIdListenerUnsubscribe = undefined;
    },
};
//# sourceMappingURL=crisp-chat-integration.js.map