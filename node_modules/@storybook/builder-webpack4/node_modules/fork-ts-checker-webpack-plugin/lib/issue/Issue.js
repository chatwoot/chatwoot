"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var IssueSeverity_1 = require("./IssueSeverity");
var IssueOrigin_1 = require("./IssueOrigin");
function isIssue(value) {
    return (!!value &&
        typeof value === 'object' &&
        IssueOrigin_1.isIssueOrigin(value.origin) &&
        IssueSeverity_1.isIssueSeverity(value.severity) &&
        !!value.code &&
        !!value.message);
}
exports.isIssue = isIssue;
function compareOptionalStrings(stringA, stringB) {
    if (stringA === stringB) {
        return 0;
    }
    if (stringA === undefined || stringA === null) {
        return -1;
    }
    if (stringB === undefined || stringB === null) {
        return 1;
    }
    return stringA.toString().localeCompare(stringB.toString());
}
function compareNumbers(numberA, numberB) {
    if (numberA === numberB) {
        return 0;
    }
    if (numberA === undefined || numberA === null) {
        return -1;
    }
    if (numberB === undefined || numberB === null) {
        return 1;
    }
    return Math.sign(numberA - numberB);
}
function compareIssues(issueA, issueB) {
    return (IssueOrigin_1.compareIssueOrigins(issueA.origin, issueB.origin) ||
        compareOptionalStrings(issueA.file, issueB.file) ||
        IssueSeverity_1.compareIssueSeverities(issueA.severity, issueB.severity) ||
        compareNumbers(issueA.line, issueB.line) ||
        compareNumbers(issueA.character, issueB.character) ||
        compareOptionalStrings(issueA.code, issueB.code) ||
        compareOptionalStrings(issueA.message, issueB.message) ||
        compareOptionalStrings(issueA.stack, issueB.stack) ||
        0 /* EqualTo */);
}
function equalsIssues(issueA, issueB) {
    return compareIssues(issueA, issueB) === 0;
}
function deduplicateAndSortIssues(issues) {
    var sortedIssues = issues.filter(isIssue).sort(compareIssues);
    return sortedIssues.filter(function (issue, index) {
        return index === 0 || !equalsIssues(issue, sortedIssues[index - 1]);
    });
}
exports.deduplicateAndSortIssues = deduplicateAndSortIssues;
//# sourceMappingURL=Issue.js.map