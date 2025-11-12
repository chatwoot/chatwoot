"use strict";
// Naive rage click implementation: If mouse has not moved further than RAGE_CLICK_THRESHOLD_PX
// over RAGE_CLICK_CLICK_COUNT clicks with max RAGE_CLICK_TIMEOUT_MS between clicks, it's
// counted as a rage click
Object.defineProperty(exports, "__esModule", { value: true });
var RAGE_CLICK_THRESHOLD_PX = 30;
var RAGE_CLICK_TIMEOUT_MS = 1000;
var RAGE_CLICK_CLICK_COUNT = 3;
var RageClick = /** @class */ (function () {
    function RageClick() {
        this.clicks = [];
    }
    RageClick.prototype.isRageClick = function (x, y, timestamp) {
        var lastClick = this.clicks[this.clicks.length - 1];
        if (lastClick &&
            Math.abs(x - lastClick.x) + Math.abs(y - lastClick.y) < RAGE_CLICK_THRESHOLD_PX &&
            timestamp - lastClick.timestamp < RAGE_CLICK_TIMEOUT_MS) {
            this.clicks.push({ x: x, y: y, timestamp: timestamp });
            if (this.clicks.length === RAGE_CLICK_CLICK_COUNT) {
                return true;
            }
        }
        else {
            this.clicks = [{ x: x, y: y, timestamp: timestamp }];
        }
        return false;
    };
    return RageClick;
}());
exports.default = RageClick;
//# sourceMappingURL=rageclick.js.map