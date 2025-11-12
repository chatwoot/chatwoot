"use strict";
/**
 * Integrate Sentry with PostHog. This will add a direct link to the person in Sentry, and an $exception event in PostHog
 *
 * ### Usage
 *
 *     Sentry.init({
 *          dsn: 'https://example',
 *          integrations: [
 *              new posthog.SentryIntegration(posthog)
 *          ]
 *     })
 *
 * @param {Object} [posthog] The posthog object
 * @param {string} [organization] Optional: The Sentry organization, used to send a direct link from PostHog to Sentry
 * @param {Number} [projectId] Optional: The Sentry project id, used to send a direct link from PostHog to Sentry
 * @param {string} [prefix] Optional: Url of a self-hosted sentry instance (default: https://sentry.io/organizations/)
 * @param {SeverityLevel[] | '*'} [severityAllowList] Optional: send events matching the provided levels. Use '*' to send all events (default: ['error'])
 */
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SentryIntegration = void 0;
exports.createEventProcessor = createEventProcessor;
exports.sentryIntegration = sentryIntegration;
var NAME = 'posthog-js';
function createEventProcessor(_posthog, _a) {
    var _b = _a === void 0 ? {} : _a, organization = _b.organization, projectId = _b.projectId, prefix = _b.prefix, _c = _b.severityAllowList, severityAllowList = _c === void 0 ? ['error'] : _c;
    return function (event) {
        var _a, _b, _c, _d, _e;
        var shouldProcessLevel = severityAllowList === '*' || severityAllowList.includes(event.level);
        if (!shouldProcessLevel || !_posthog.__loaded)
            return event;
        if (!event.tags)
            event.tags = {};
        var personUrl = _posthog.requestRouter.endpointFor('ui', "/project/".concat(_posthog.config.token, "/person/").concat(_posthog.get_distinct_id()));
        event.tags['PostHog Person URL'] = personUrl;
        if (_posthog.sessionRecordingStarted()) {
            event.tags['PostHog Recording URL'] = _posthog.get_session_replay_url({ withTimestamp: true });
        }
        var exceptions = ((_a = event.exception) === null || _a === void 0 ? void 0 : _a.values) || [];
        var exceptionList = exceptions.map(function (exception) {
            return __assign(__assign({}, exception), { stacktrace: exception.stacktrace
                    ? __assign(__assign({}, exception.stacktrace), { type: 'raw', frames: (exception.stacktrace.frames || []).map(function (frame) {
                            return __assign(__assign({}, frame), { platform: 'web:javascript' });
                        }) }) : undefined });
        });
        var data = {
            // PostHog Exception Properties,
            $exception_message: ((_b = exceptions[0]) === null || _b === void 0 ? void 0 : _b.value) || event.message,
            $exception_type: (_c = exceptions[0]) === null || _c === void 0 ? void 0 : _c.type,
            $exception_personURL: personUrl,
            $exception_level: event.level,
            $exception_list: exceptionList,
            // Sentry Exception Properties
            $sentry_event_id: event.event_id,
            $sentry_exception: event.exception,
            $sentry_exception_message: ((_d = exceptions[0]) === null || _d === void 0 ? void 0 : _d.value) || event.message,
            $sentry_exception_type: (_e = exceptions[0]) === null || _e === void 0 ? void 0 : _e.type,
            $sentry_tags: event.tags,
        };
        if (organization && projectId) {
            data['$sentry_url'] =
                (prefix || 'https://sentry.io/organizations/') +
                    organization +
                    '/issues/?project=' +
                    projectId +
                    '&query=' +
                    event.event_id;
        }
        _posthog.exceptions.sendExceptionEvent(data);
        return event;
    };
}
// V8 integration - function based
function sentryIntegration(_posthog, options) {
    var processor = createEventProcessor(_posthog, options);
    return {
        name: NAME,
        processEvent: function (event) {
            return processor(event);
        },
    };
}
// V7 integration - class based
var SentryIntegration = /** @class */ (function () {
    function SentryIntegration(_posthog, organization, projectId, prefix, severityAllowList) {
        // setupOnce gets called by Sentry when it intializes the plugin
        this.name = NAME;
        this.setupOnce = function (addGlobalEventProcessor) {
            addGlobalEventProcessor(createEventProcessor(_posthog, { organization: organization, projectId: projectId, prefix: prefix, severityAllowList: severityAllowList }));
        };
    }
    return SentryIntegration;
}());
exports.SentryIntegration = SentryIntegration;
//# sourceMappingURL=sentry-integration.js.map