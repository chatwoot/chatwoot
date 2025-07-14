"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.pWhile = void 0;
var tslib_1 = require("tslib");
var pWhile = function (condition, action) { return tslib_1.__awaiter(void 0, void 0, void 0, function () {
    var loop;
    return tslib_1.__generator(this, function (_a) {
        loop = function (actionResult) { return tslib_1.__awaiter(void 0, void 0, void 0, function () {
            var _a;
            return tslib_1.__generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        if (!condition(actionResult)) return [3 /*break*/, 2];
                        _a = loop;
                        return [4 /*yield*/, action()];
                    case 1: return [2 /*return*/, _a.apply(void 0, [_b.sent()])];
                    case 2: return [2 /*return*/];
                }
            });
        }); };
        return [2 /*return*/, loop(undefined)];
    });
}); };
exports.pWhile = pWhile;
//# sourceMappingURL=p-while.js.map