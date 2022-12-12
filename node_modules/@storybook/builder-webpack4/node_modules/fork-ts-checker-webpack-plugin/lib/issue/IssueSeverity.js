"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var IssueSeverity = {
    ERROR: 'error',
    WARNING: 'warning'
};
exports.IssueSeverity = IssueSeverity;
function isIssueSeverity(value) {
    return [IssueSeverity.ERROR, IssueSeverity.WARNING].includes(value);
}
exports.isIssueSeverity = isIssueSeverity;
function compareIssueSeverities(severityA, severityB) {
    var _a = [severityA, severityB].map(function (severity) {
        return [IssueSeverity.WARNING /* 0 */, IssueSeverity.ERROR /* 1 */].indexOf(severity);
    }), priorityA = _a[0], priorityB = _a[1];
    return Math.sign(priorityB - priorityA);
}
exports.compareIssueSeverities = compareIssueSeverities;
//# sourceMappingURL=IssueSeverity.js.map