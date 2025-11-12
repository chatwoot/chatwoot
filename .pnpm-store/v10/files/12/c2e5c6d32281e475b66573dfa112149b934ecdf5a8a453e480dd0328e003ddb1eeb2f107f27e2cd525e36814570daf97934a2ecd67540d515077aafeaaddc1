"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var globals_1 = require("../utils/globals");
var logger_1 = require("../utils/logger");
var logger = (0, logger_1.createLogger)('[PostHog Intercom integration]');
var reportedSessionIds = new Set();
var sessionIdListenerUnsubscribe = undefined;
globals_1.assignableWindow.__PosthogExtensions__ = globals_1.assignableWindow.__PosthogExtensions__ || {};
globals_1.assignableWindow.__PosthogExtensions__.integrations = globals_1.assignableWindow.__PosthogExtensions__.integrations || {};
globals_1.assignableWindow.__PosthogExtensions__.integrations.intercom = {
    start: function (posthog) {
        var _a;
        if (!((_a = posthog.config.integrations) === null || _a === void 0 ? void 0 : _a.intercom)) {
            return;
        }
        var intercom = globals_1.assignableWindow.Intercom;
        if (!intercom) {
            logger.warn('Intercom not found while initializing the integration');
            return;
        }
        var updateIntercom = function () {
            var replayUrl = posthog.get_session_replay_url();
            var personUrl = posthog.requestRouter.endpointFor('ui', "/project/".concat(posthog.config.token, "/person/").concat(posthog.get_distinct_id()));
            intercom('update', {
                latestPosthogReplayURL: replayUrl,
                latestPosthogPersonURL: personUrl,
            });
            intercom('trackEvent', 'posthog:sessionInfo', { replayUrl: replayUrl, personUrl: personUrl });
        };
        // this is called immediately if there's a session id
        // and then again whenever the session id changes
        sessionIdListenerUnsubscribe = posthog.onSessionId(function (sessionId) {
            if (!reportedSessionIds.has(sessionId)) {
                updateIntercom();
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
//# sourceMappingURL=intercom-integration.js.map