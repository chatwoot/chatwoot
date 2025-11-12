"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setupSegmentIntegration = setupSegmentIntegration;
var logger_1 = require("../utils/logger");
var constants_1 = require("../constants");
var core_1 = require("@posthog/core");
var uuidv7_1 = require("../uuidv7");
var logger = (0, logger_1.createLogger)('[SegmentIntegration]');
var createSegmentIntegration = function (posthog) {
    if (!Promise || !Promise.resolve) {
        logger.warn('This browser does not have Promise support, and can not use the segment integration');
    }
    var enrichEvent = function (ctx, eventName) {
        if (!eventName) {
            return ctx;
        }
        if (!ctx.event.userId && ctx.event.anonymousId !== posthog.get_distinct_id()) {
            // This is our only way of detecting that segment's analytics.reset() has been called so we also call it
            logger.info('No userId set, resetting PostHog');
            posthog.reset();
        }
        if (ctx.event.userId && ctx.event.userId !== posthog.get_distinct_id()) {
            logger.info('UserId set, identifying with PostHog');
            posthog.identify(ctx.event.userId);
        }
        var additionalProperties = posthog.calculateEventProperties(eventName, ctx.event.properties);
        ctx.event.properties = Object.assign({}, additionalProperties, ctx.event.properties);
        return ctx;
    };
    return {
        name: 'PostHog JS',
        type: 'enrichment',
        version: '1.0.0',
        isLoaded: function () { return true; },
        // check and early return above
        // eslint-disable-next-line compat/compat
        load: function () { return Promise.resolve(); },
        track: function (ctx) { return enrichEvent(ctx, ctx.event.event); },
        page: function (ctx) { return enrichEvent(ctx, '$pageview'); },
        identify: function (ctx) { return enrichEvent(ctx, '$identify'); },
        screen: function (ctx) { return enrichEvent(ctx, '$screen'); },
    };
};
function setupPostHogFromSegment(posthog, done) {
    var segment = posthog.config.segment;
    if (!segment) {
        return done();
    }
    var bootstrapUser = function (user) {
        // Use segments anonymousId instead
        var getSegmentAnonymousId = function () { return user.anonymousId() || (0, uuidv7_1.uuidv7)(); };
        posthog.config.get_device_id = getSegmentAnonymousId;
        // If a segment user ID exists, set it as the distinct_id
        if (user.id()) {
            posthog.register({
                distinct_id: user.id(),
                $device_id: getSegmentAnonymousId(),
            });
            posthog.persistence.set_property(constants_1.USER_STATE, 'identified');
        }
        done();
    };
    var segmentUser = segment.user();
    // If segmentUser is a promise then we need to wait for it to resolve
    if ('then' in segmentUser && (0, core_1.isFunction)(segmentUser.then)) {
        segmentUser.then(function (user) { return bootstrapUser(user); });
    }
    else {
        bootstrapUser(segmentUser);
    }
}
function setupSegmentIntegration(posthog, done) {
    var segment = posthog.config.segment;
    if (!segment) {
        return done();
    }
    setupPostHogFromSegment(posthog, function () {
        segment.register(createSegmentIntegration(posthog)).then(function () {
            done();
        });
    });
}
//# sourceMappingURL=segment-integration.js.map