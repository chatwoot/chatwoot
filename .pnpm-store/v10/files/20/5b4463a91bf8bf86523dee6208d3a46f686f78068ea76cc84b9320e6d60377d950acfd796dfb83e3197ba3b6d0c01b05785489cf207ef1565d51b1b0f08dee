"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.analyticsNode = exports.post = void 0;
var tslib_1 = require("tslib");
var node_fetch_1 = tslib_1.__importDefault(require("node-fetch"));
var version_1 = require("../../generated/version");
var btoa = function (val) { return Buffer.from(val).toString('base64'); };
function post(event, writeKey) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var res;
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, (0, node_fetch_1.default)("https://api.june.so/sdk/".concat(event.type), {
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
exports.post = post;
function analyticsNode(settings) {
    var _this = this;
    var send = function (ctx) { return tslib_1.__awaiter(_this, void 0, void 0, function () {
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    ctx.updateEvent('context.library.name', 'analytics-node-next');
                    ctx.updateEvent('context.library.version', version_1.version);
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
exports.analyticsNode = analyticsNode;
//# sourceMappingURL=index.js.map