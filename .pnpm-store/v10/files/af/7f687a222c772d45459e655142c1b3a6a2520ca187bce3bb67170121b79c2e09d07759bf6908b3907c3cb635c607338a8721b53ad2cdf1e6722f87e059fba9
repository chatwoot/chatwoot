"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.IN_APP_SURVEY_TYPES = exports.setSurveySeenOnLocalStorage = exports.getSurveySeenKey = exports.getSurveyInteractionProperty = exports.SURVEY_IN_PROGRESS_PREFIX = exports.SURVEY_SEEN_PREFIX = exports.SURVEY_LOGGER = void 0;
exports.isSurveyRunning = isSurveyRunning;
exports.doesSurveyActivateByEvent = doesSurveyActivateByEvent;
exports.doesSurveyActivateByAction = doesSurveyActivateByAction;
var posthog_surveys_types_1 = require("../posthog-surveys-types");
var logger_1 = require("../utils/logger");
exports.SURVEY_LOGGER = (0, logger_1.createLogger)('[Surveys]');
function isSurveyRunning(survey) {
    return !!(survey.start_date && !survey.end_date);
}
function doesSurveyActivateByEvent(survey) {
    var _a, _b, _c;
    return !!((_c = (_b = (_a = survey.conditions) === null || _a === void 0 ? void 0 : _a.events) === null || _b === void 0 ? void 0 : _b.values) === null || _c === void 0 ? void 0 : _c.length);
}
function doesSurveyActivateByAction(survey) {
    var _a, _b, _c;
    return !!((_c = (_b = (_a = survey.conditions) === null || _a === void 0 ? void 0 : _a.actions) === null || _b === void 0 ? void 0 : _b.values) === null || _c === void 0 ? void 0 : _c.length);
}
exports.SURVEY_SEEN_PREFIX = 'seenSurvey_';
exports.SURVEY_IN_PROGRESS_PREFIX = 'inProgressSurvey_';
var getSurveyInteractionProperty = function (survey, action) {
    var surveyProperty = "$survey_".concat(action, "/").concat(survey.id);
    if (survey.current_iteration && survey.current_iteration > 0) {
        surveyProperty = "$survey_".concat(action, "/").concat(survey.id, "/").concat(survey.current_iteration);
    }
    return surveyProperty;
};
exports.getSurveyInteractionProperty = getSurveyInteractionProperty;
var getSurveySeenKey = function (survey) {
    var surveySeenKey = "".concat(exports.SURVEY_SEEN_PREFIX).concat(survey.id);
    if (survey.current_iteration && survey.current_iteration > 0) {
        surveySeenKey = "".concat(exports.SURVEY_SEEN_PREFIX).concat(survey.id, "_").concat(survey.current_iteration);
    }
    return surveySeenKey;
};
exports.getSurveySeenKey = getSurveySeenKey;
var setSurveySeenOnLocalStorage = function (survey) {
    var isSurveySeen = localStorage.getItem((0, exports.getSurveySeenKey)(survey));
    // if survey is already seen, no need to set it again
    if (isSurveySeen) {
        return;
    }
    localStorage.setItem((0, exports.getSurveySeenKey)(survey), 'true');
};
exports.setSurveySeenOnLocalStorage = setSurveySeenOnLocalStorage;
// These surveys are relevant for the getActiveMatchingSurveys method. They are used to
// display surveys in our customer's application. Any new in-app survey type should be added here.
exports.IN_APP_SURVEY_TYPES = [posthog_surveys_types_1.SurveyType.Popover, posthog_surveys_types_1.SurveyType.Widget, posthog_surveys_types_1.SurveyType.API];
//# sourceMappingURL=survey-utils.js.map