"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.propertyComparisons = void 0;
exports.getPersonPropertiesHash = getPersonPropertiesHash;
var request_1 = require("../request");
var regex_utils_1 = require("./regex-utils");
function getPersonPropertiesHash(distinct_id, userPropertiesToSet, userPropertiesToSetOnce) {
    return (0, request_1.jsonStringify)({ distinct_id: distinct_id, userPropertiesToSet: userPropertiesToSet, userPropertiesToSetOnce: userPropertiesToSetOnce });
}
exports.propertyComparisons = {
    exact: function (targets, values) { return values.some(function (value) { return targets.some(function (target) { return value === target; }); }); },
    is_not: function (targets, values) { return values.every(function (value) { return targets.every(function (target) { return value !== target; }); }); },
    regex: function (targets, values) { return values.some(function (value) { return targets.some(function (target) { return (0, regex_utils_1.isMatchingRegex)(value, target); }); }); },
    not_regex: function (targets, values) { return values.every(function (value) { return targets.every(function (target) { return !(0, regex_utils_1.isMatchingRegex)(value, target); }); }); },
    icontains: function (targets, values) {
        return values.map(toLowerCase).some(function (value) { return targets.map(toLowerCase).some(function (target) { return value.includes(target); }); });
    },
    not_icontains: function (targets, values) {
        return values.map(toLowerCase).every(function (value) { return targets.map(toLowerCase).every(function (target) { return !value.includes(target); }); });
    },
};
var toLowerCase = function (v) { return v.toLowerCase(); };
//# sourceMappingURL=property-utils.js.map