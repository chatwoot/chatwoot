import { __assign } from "tslib";
import { isPlanEventEnabled } from '../../lib/is-plan-event-enabled';
function disabledActionDestinations(plan, settings) {
    var _a, _b;
    if (!plan || !Object.keys(plan)) {
        return {};
    }
    var disabledIntegrations = plan.integrations
        ? Object.keys(plan.integrations).filter(function (i) { return plan.integrations[i] === false; })
        : [];
    // This accounts for cases like Fullstory, where the settings.integrations
    // contains a "Fullstory" object but settings.remotePlugins contains "Fullstory (Actions)"
    var disabledRemotePlugins = [];
    ((_a = settings.remotePlugins) !== null && _a !== void 0 ? _a : []).forEach(function (p) {
        disabledIntegrations.forEach(function (int) {
            if (p.name.includes(int) || int.includes(p.name)) {
                disabledRemotePlugins.push(p.name);
            }
        });
    });
    return ((_b = settings.remotePlugins) !== null && _b !== void 0 ? _b : []).reduce(function (acc, p) {
        if (p.settings['subscriptions']) {
            if (disabledRemotePlugins.includes(p.name)) {
                // @ts-expect-error element implicitly has an 'any' type because p.settings is a JSONObject
                p.settings['subscriptions'].forEach(
                // @ts-expect-error parameter 'sub' implicitly has an 'any' type
                function (sub) { return (acc["".concat(p.name, " ").concat(sub.partnerAction)] = false); });
            }
        }
        return acc;
    }, {});
}
export function schemaFilter(track, settings) {
    function filter(ctx) {
        var plan = track;
        var ev = ctx.event.event;
        if (plan && ev) {
            var planEvent = plan[ev];
            if (!isPlanEventEnabled(plan, planEvent)) {
                ctx.updateEvent('integrations', __assign(__assign({}, ctx.event.integrations), { All: false, 'june.so': true }));
                return ctx;
            }
            else {
                var disabledActions = disabledActionDestinations(planEvent, settings);
                ctx.updateEvent('integrations', __assign(__assign(__assign({}, ctx.event.integrations), planEvent === null || planEvent === void 0 ? void 0 : planEvent.integrations), disabledActions));
            }
        }
        return ctx;
    }
    return {
        name: 'Schema Filter',
        version: '0.1.0',
        isLoaded: function () { return true; },
        load: function () { return Promise.resolve(); },
        type: 'before',
        page: filter,
        alias: filter,
        track: filter,
        identify: filter,
        group: filter,
    };
}
//# sourceMappingURL=index.js.map