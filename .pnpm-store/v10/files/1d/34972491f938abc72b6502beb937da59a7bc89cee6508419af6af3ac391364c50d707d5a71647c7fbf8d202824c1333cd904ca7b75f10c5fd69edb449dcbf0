import { __awaiter, __generator } from "tslib";
import fetch from 'node-fetch';
import { version } from '../../generated/version';
var btoa = function (val) { return Buffer.from(val).toString('base64'); };
export function post(event, writeKey) {
    return __awaiter(this, void 0, void 0, function () {
        var res;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, fetch("https://api.june.so/sdk/".concat(event.type), {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'User-Agent': 'analytics-node-next/latest',
                            Authorization: "Basic ".concat(btoa(writeKey)),
                        },
                        body: JSON.stringify(event),
                    })];
                case 1:
                    res = _a.sent();
                    if (!res.ok) {
                        throw new Error('Message Rejected');
                    }
                    return [2 /*return*/, event];
            }
        });
    });
}
export function analyticsNode(settings) {
    var _this = this;
    var send = function (ctx) { return __awaiter(_this, void 0, void 0, function () {
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    ctx.updateEvent('context.library.name', 'analytics-node-next');
                    ctx.updateEvent('context.library.version', version);
                    ctx.updateEvent('_metadata.nodeVersion', process.versions.node);
                    return [4 /*yield*/, post(ctx.event, settings.writeKey)];
                case 1:
                    _a.sent();
                    return [2 /*return*/, ctx];
            }
        });
    }); };
    var plugin = {
        name: settings.name,
        type: settings.type,
        version: settings.version,
        load: function (ctx) { return Promise.resolve(ctx); },
        isLoaded: function () { return true; },
        track: send,
        identify: send,
        page: send,
        alias: send,
        group: send,
        screen: send,
    };
    return plugin;
}
//# sourceMappingURL=index.js.map