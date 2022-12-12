"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var IssueOrigin = {
    TYPESCRIPT: 'typescript',
    ESLINT: 'eslint',
    INTERNAL: 'internal'
};
exports.IssueOrigin = IssueOrigin;
function isIssueOrigin(value) {
    return [
        IssueOrigin.TYPESCRIPT,
        IssueOrigin.ESLINT,
        IssueOrigin.INTERNAL
    ].includes(value);
}
exports.isIssueOrigin = isIssueOrigin;
function compareIssueOrigins(originA, originB) {
    var _a = [originA, originB].map(function (origin) {
        return [
            IssueOrigin.ESLINT /* 0 */,
            IssueOrigin.TYPESCRIPT /* 1 */,
            IssueOrigin.INTERNAL /* 2 */
        ].indexOf(origin);
    }), priorityA = _a[0], priorityB = _a[1];
    return Math.sign(priorityB - priorityA);
}
exports.compareIssueOrigins = compareIssueOrigins;
//# sourceMappingURL=IssueOrigin.js.map