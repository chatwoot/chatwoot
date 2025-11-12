"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
var __read = (this && this.__read) || function (o, n) {
    var m = typeof Symbol === "function" && o[Symbol.iterator];
    if (!m) return o;
    var i = m.call(o), r, ar = [], e;
    try {
        while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
    }
    catch (error) { e = { error: error }; }
    finally {
        try {
            if (r && !r.done && (m = i["return"])) m.call(i);
        }
        finally { if (e) throw e.error; }
    }
    return ar;
};
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.clearInProgressSurveyState = exports.isSurveyInProgress = exports.getInProgressSurveyState = exports.setInProgressSurveyState = exports.renderChildrenAsTextOrHtml = exports.useSurveyContext = exports.SurveyContext = exports.hasWaitPeriodPassed = exports.getSurveySeen = exports.canActivateRepeatedly = exports.hasEvents = exports.getDisplayOrderQuestions = exports.getDisplayOrderChoices = exports.shuffle = exports.dismissedSurveyEvent = exports.sendSurveyEvent = exports.retrieveSurveyShadow = exports.addSurveyCSSVariablesToElement = exports.defaultSurveyAppearance = void 0;
exports.getFontFamily = getFontFamily;
exports.getSurveyResponseKey = getSurveyResponseKey;
exports.getSurveyStylesheet = getSurveyStylesheet;
exports.doesSurveyUrlMatch = doesSurveyUrlMatch;
exports.doesSurveyDeviceTypesMatch = doesSurveyDeviceTypesMatch;
exports.doesSurveyMatchSelector = doesSurveyMatchSelector;
exports.getSurveyContainerClass = getSurveyContainerClass;
var preact_1 = require("preact");
var posthog_surveys_types_1 = require("../../posthog-surveys-types");
var globals_1 = require("../../utils/globals");
var survey_utils_1 = require("../../utils/survey-utils");
var core_1 = require("@posthog/core");
var user_agent_utils_1 = require("../../utils/user-agent-utils");
var property_utils_1 = require("../../utils/property-utils");
var stylesheet_loader_1 = require("../utils/stylesheet-loader");
// We cast the types here which is dangerous but protected by the top level generateSurveys call
var window = globals_1.window;
var document = globals_1.document;
var survey_css_1 = __importDefault(require("./survey.css"));
var hooks_1 = require("preact/hooks");
function getFontFamily(fontFamily) {
    if (fontFamily === 'inherit') {
        return 'inherit';
    }
    var defaultFontStack = 'BlinkMacSystemFont, "Inter", "Segoe UI", "Roboto", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"';
    return fontFamily ? "".concat(fontFamily, ", ").concat(defaultFontStack) : "-apple-system, ".concat(defaultFontStack);
}
function getSurveyResponseKey(questionId) {
    return "$survey_response_".concat(questionId);
}
var BLACK_TEXT_COLOR = '#020617'; // Maps out to text-slate-950 from tailwind colors. Intended for text use outside interactive elements like buttons
// Keep in sync with defaultSurveyAppearance on the main app
exports.defaultSurveyAppearance = {
    fontFamily: 'inherit',
    backgroundColor: '#eeeded',
    submitButtonColor: 'black',
    submitButtonTextColor: 'white',
    ratingButtonColor: 'white',
    ratingButtonActiveColor: 'black',
    borderColor: '#c9c6c6',
    placeholder: 'Start typing...',
    whiteLabel: false,
    displayThankYouMessage: true,
    thankYouMessageHeader: 'Thank you for your feedback!',
    position: posthog_surveys_types_1.SurveyPosition.Right,
    widgetType: posthog_surveys_types_1.SurveyWidgetType.Tab,
    widgetLabel: 'Feedback',
    widgetColor: 'black',
    zIndex: '2147483647',
    disabledButtonOpacity: '0.6',
    maxWidth: '300px',
    textSubtleColor: '#939393',
    boxPadding: '20px 24px',
    boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
    borderRadius: '10px',
    shuffleQuestions: false,
    surveyPopupDelaySeconds: undefined,
    // Not customizable atm
    outlineColor: 'rgba(59, 130, 246, 0.8)',
    inputBackground: 'white',
    inputTextColor: BLACK_TEXT_COLOR,
    scrollbarThumbColor: 'var(--ph-survey-border-color)',
    scrollbarTrackColor: 'var(--ph-survey-background-color)',
};
var addSurveyCSSVariablesToElement = function (element, type, appearance) {
    var effectiveAppearance = __assign(__assign({}, exports.defaultSurveyAppearance), appearance);
    var hostStyle = element.style;
    var surveyHasBottomBorder = ![posthog_surveys_types_1.SurveyPosition.Center, posthog_surveys_types_1.SurveyPosition.Left, posthog_surveys_types_1.SurveyPosition.Right].includes(effectiveAppearance.position) ||
        (type === posthog_surveys_types_1.SurveyType.Widget && (appearance === null || appearance === void 0 ? void 0 : appearance.widgetType) === posthog_surveys_types_1.SurveyWidgetType.Tab);
    hostStyle.setProperty('--ph-survey-font-family', getFontFamily(effectiveAppearance.fontFamily));
    hostStyle.setProperty('--ph-survey-box-padding', effectiveAppearance.boxPadding);
    hostStyle.setProperty('--ph-survey-max-width', effectiveAppearance.maxWidth);
    hostStyle.setProperty('--ph-survey-z-index', effectiveAppearance.zIndex);
    hostStyle.setProperty('--ph-survey-border-color', effectiveAppearance.borderColor);
    // Non-bottom surveys or tab surveys have the border bottom
    if (surveyHasBottomBorder) {
        hostStyle.setProperty('--ph-survey-border-radius', effectiveAppearance.borderRadius);
        hostStyle.setProperty('--ph-survey-border-bottom', '1.5px solid var(--ph-survey-border-color)');
    }
    else {
        hostStyle.setProperty('--ph-survey-border-bottom', 'none');
        hostStyle.setProperty('--ph-survey-border-radius', "".concat(effectiveAppearance.borderRadius, " ").concat(effectiveAppearance.borderRadius, " 0 0"));
    }
    hostStyle.setProperty('--ph-survey-background-color', effectiveAppearance.backgroundColor);
    hostStyle.setProperty('--ph-survey-box-shadow', effectiveAppearance.boxShadow);
    hostStyle.setProperty('--ph-survey-disabled-button-opacity', effectiveAppearance.disabledButtonOpacity);
    hostStyle.setProperty('--ph-survey-submit-button-color', effectiveAppearance.submitButtonColor);
    hostStyle.setProperty('--ph-survey-submit-button-text-color', (appearance === null || appearance === void 0 ? void 0 : appearance.submitButtonTextColor) || getContrastingTextColor(effectiveAppearance.submitButtonColor));
    hostStyle.setProperty('--ph-survey-rating-bg-color', effectiveAppearance.ratingButtonColor);
    hostStyle.setProperty('--ph-survey-rating-text-color', getContrastingTextColor(effectiveAppearance.ratingButtonColor));
    hostStyle.setProperty('--ph-survey-rating-active-bg-color', effectiveAppearance.ratingButtonActiveColor);
    hostStyle.setProperty('--ph-survey-rating-active-text-color', getContrastingTextColor(effectiveAppearance.ratingButtonActiveColor));
    hostStyle.setProperty('--ph-survey-text-primary-color', getContrastingTextColor(effectiveAppearance.backgroundColor));
    hostStyle.setProperty('--ph-survey-text-subtle-color', effectiveAppearance.textSubtleColor);
    hostStyle.setProperty('--ph-widget-color', effectiveAppearance.widgetColor);
    hostStyle.setProperty('--ph-widget-text-color', getContrastingTextColor(effectiveAppearance.widgetColor));
    hostStyle.setProperty('--ph-widget-z-index', effectiveAppearance.zIndex);
    // Adjust input/choice background slightly if main background is white
    if (effectiveAppearance.backgroundColor === 'white') {
        hostStyle.setProperty('--ph-survey-input-background', '#f8f8f8');
    }
    hostStyle.setProperty('--ph-survey-input-background', effectiveAppearance.inputBackground);
    hostStyle.setProperty('--ph-survey-input-text-color', getContrastingTextColor(effectiveAppearance.inputBackground));
    hostStyle.setProperty('--ph-survey-scrollbar-thumb-color', effectiveAppearance.scrollbarThumbColor);
    hostStyle.setProperty('--ph-survey-scrollbar-track-color', effectiveAppearance.scrollbarTrackColor);
    hostStyle.setProperty('--ph-survey-outline-color', effectiveAppearance.outlineColor);
};
exports.addSurveyCSSVariablesToElement = addSurveyCSSVariablesToElement;
function nameToHex(name) {
    return {
        aliceblue: '#f0f8ff',
        antiquewhite: '#faebd7',
        aqua: '#00ffff',
        aquamarine: '#7fffd4',
        azure: '#f0ffff',
        beige: '#f5f5dc',
        bisque: '#ffe4c4',
        black: '#000000',
        blanchedalmond: '#ffebcd',
        blue: '#0000ff',
        blueviolet: '#8a2be2',
        brown: '#a52a2a',
        burlywood: '#deb887',
        cadetblue: '#5f9ea0',
        chartreuse: '#7fff00',
        chocolate: '#d2691e',
        coral: '#ff7f50',
        cornflowerblue: '#6495ed',
        cornsilk: '#fff8dc',
        crimson: '#dc143c',
        cyan: '#00ffff',
        darkblue: '#00008b',
        darkcyan: '#008b8b',
        darkgoldenrod: '#b8860b',
        darkgray: '#a9a9a9',
        darkgreen: '#006400',
        darkkhaki: '#bdb76b',
        darkmagenta: '#8b008b',
        darkolivegreen: '#556b2f',
        darkorange: '#ff8c00',
        darkorchid: '#9932cc',
        darkred: '#8b0000',
        darksalmon: '#e9967a',
        darkseagreen: '#8fbc8f',
        darkslateblue: '#483d8b',
        darkslategray: '#2f4f4f',
        darkturquoise: '#00ced1',
        darkviolet: '#9400d3',
        deeppink: '#ff1493',
        deepskyblue: '#00bfff',
        dimgray: '#696969',
        dodgerblue: '#1e90ff',
        firebrick: '#b22222',
        floralwhite: '#fffaf0',
        forestgreen: '#228b22',
        fuchsia: '#ff00ff',
        gainsboro: '#dcdcdc',
        ghostwhite: '#f8f8ff',
        gold: '#ffd700',
        goldenrod: '#daa520',
        gray: '#808080',
        green: '#008000',
        greenyellow: '#adff2f',
        honeydew: '#f0fff0',
        hotpink: '#ff69b4',
        'indianred ': '#cd5c5c',
        indigo: '#4b0082',
        ivory: '#fffff0',
        khaki: '#f0e68c',
        lavender: '#e6e6fa',
        lavenderblush: '#fff0f5',
        lawngreen: '#7cfc00',
        lemonchiffon: '#fffacd',
        lightblue: '#add8e6',
        lightcoral: '#f08080',
        lightcyan: '#e0ffff',
        lightgoldenrodyellow: '#fafad2',
        lightgrey: '#d3d3d3',
        lightgreen: '#90ee90',
        lightpink: '#ffb6c1',
        lightsalmon: '#ffa07a',
        lightseagreen: '#20b2aa',
        lightskyblue: '#87cefa',
        lightslategray: '#778899',
        lightsteelblue: '#b0c4de',
        lightyellow: '#ffffe0',
        lime: '#00ff00',
        limegreen: '#32cd32',
        linen: '#faf0e6',
        magenta: '#ff00ff',
        maroon: '#800000',
        mediumaquamarine: '#66cdaa',
        mediumblue: '#0000cd',
        mediumorchid: '#ba55d3',
        mediumpurple: '#9370d8',
        mediumseagreen: '#3cb371',
        mediumslateblue: '#7b68ee',
        mediumspringgreen: '#00fa9a',
        mediumturquoise: '#48d1cc',
        mediumvioletred: '#c71585',
        midnightblue: '#191970',
        mintcream: '#f5fffa',
        mistyrose: '#ffe4e1',
        moccasin: '#ffe4b5',
        navajowhite: '#ffdead',
        navy: '#000080',
        oldlace: '#fdf5e6',
        olive: '#808000',
        olivedrab: '#6b8e23',
        orange: '#ffa500',
        orangered: '#ff4500',
        orchid: '#da70d6',
        palegoldenrod: '#eee8aa',
        palegreen: '#98fb98',
        paleturquoise: '#afeeee',
        palevioletred: '#d87093',
        papayawhip: '#ffefd5',
        peachpuff: '#ffdab9',
        peru: '#cd853f',
        pink: '#ffc0cb',
        plum: '#dda0dd',
        powderblue: '#b0e0e6',
        purple: '#800080',
        red: '#ff0000',
        rosybrown: '#bc8f8f',
        royalblue: '#4169e1',
        saddlebrown: '#8b4513',
        salmon: '#fa8072',
        sandybrown: '#f4a460',
        seagreen: '#2e8b57',
        seashell: '#fff5ee',
        sienna: '#a0522d',
        silver: '#c0c0c0',
        skyblue: '#87ceeb',
        slateblue: '#6a5acd',
        slategray: '#708090',
        snow: '#fffafa',
        springgreen: '#00ff7f',
        steelblue: '#4682b4',
        tan: '#d2b48c',
        teal: '#008080',
        thistle: '#d8bfd8',
        tomato: '#ff6347',
        turquoise: '#40e0d0',
        violet: '#ee82ee',
        wheat: '#f5deb3',
        white: '#ffffff',
        whitesmoke: '#f5f5f5',
        yellow: '#ffff00',
        yellowgreen: '#9acd32',
    }[name.toLowerCase()];
}
function hex2rgb(c) {
    if (c[0] === '#') {
        var hexColor = c.replace(/^#/, '');
        var r = parseInt(hexColor.slice(0, 2), 16);
        var g = parseInt(hexColor.slice(2, 4), 16);
        var b = parseInt(hexColor.slice(4, 6), 16);
        return 'rgb(' + r + ',' + g + ',' + b + ')';
    }
    return 'rgb(255, 255, 255)';
}
function getContrastingTextColor(color) {
    if (color === void 0) { color = exports.defaultSurveyAppearance.backgroundColor; }
    var rgb;
    if (color[0] === '#') {
        rgb = hex2rgb(color);
    }
    if (color.startsWith('rgb')) {
        rgb = color;
    }
    // otherwise it's a color name
    var nameColorToHex = nameToHex(color);
    if (nameColorToHex) {
        rgb = hex2rgb(nameColorToHex);
    }
    if (!rgb) {
        return BLACK_TEXT_COLOR;
    }
    var colorMatch = rgb.match(/^rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*(\d+(?:\.\d+)?))?\)$/);
    if (colorMatch) {
        var r = parseInt(colorMatch[1]);
        var g = parseInt(colorMatch[2]);
        var b = parseInt(colorMatch[3]);
        var hsp = Math.sqrt(0.299 * (r * r) + 0.587 * (g * g) + 0.114 * (b * b));
        return hsp > 127.5 ? BLACK_TEXT_COLOR : 'white';
    }
    return BLACK_TEXT_COLOR;
}
function getSurveyStylesheet(posthog) {
    var stylesheet = (0, stylesheet_loader_1.prepareStylesheet)(document, typeof survey_css_1.default === 'string' ? survey_css_1.default : '', posthog);
    stylesheet === null || stylesheet === void 0 ? void 0 : stylesheet.setAttribute('data-ph-survey-style', 'true');
    return stylesheet;
}
var retrieveSurveyShadow = function (survey, posthog, element) {
    var widgetClassName = getSurveyContainerClass(survey);
    var existingDiv = document.querySelector(".".concat(widgetClassName));
    if (existingDiv && existingDiv.shadowRoot) {
        return {
            shadow: existingDiv.shadowRoot,
            isNewlyCreated: false,
        };
    }
    // If it doesn't exist, create it
    var div = document.createElement('div');
    (0, exports.addSurveyCSSVariablesToElement)(div, survey.type, survey.appearance);
    div.className = widgetClassName;
    var shadow = div.attachShadow({ mode: 'open' });
    var stylesheet = getSurveyStylesheet(posthog);
    if (stylesheet) {
        var existingStylesheet = shadow.querySelector('style');
        if (existingStylesheet) {
            shadow.removeChild(existingStylesheet);
        }
        shadow.appendChild(stylesheet);
    }
    ;
    (element ? element : document.body).appendChild(div);
    return {
        shadow: shadow,
        isNewlyCreated: true,
    };
};
exports.retrieveSurveyShadow = retrieveSurveyShadow;
var getSurveyResponseValue = function (responses, questionId) {
    if (!questionId) {
        return null;
    }
    var response = responses[getSurveyResponseKey(questionId)];
    if ((0, core_1.isArray)(response)) {
        return __spreadArray([], __read(response), false);
    }
    return response;
};
var sendSurveyEvent = function (_a) {
    var _b, _c;
    var _d;
    var responses = _a.responses, survey = _a.survey, surveySubmissionId = _a.surveySubmissionId, posthog = _a.posthog, isSurveyCompleted = _a.isSurveyCompleted;
    if (!posthog) {
        survey_utils_1.SURVEY_LOGGER.error('[survey sent] event not captured, PostHog instance not found.');
        return;
    }
    (0, survey_utils_1.setSurveySeenOnLocalStorage)(survey);
    posthog.capture(posthog_surveys_types_1.SurveyEventName.SENT, __assign(__assign((_b = {}, _b[posthog_surveys_types_1.SurveyEventProperties.SURVEY_NAME] = survey.name, _b[posthog_surveys_types_1.SurveyEventProperties.SURVEY_ID] = survey.id, _b[posthog_surveys_types_1.SurveyEventProperties.SURVEY_ITERATION] = survey.current_iteration, _b[posthog_surveys_types_1.SurveyEventProperties.SURVEY_ITERATION_START_DATE] = survey.current_iteration_start_date, _b[posthog_surveys_types_1.SurveyEventProperties.SURVEY_QUESTIONS] = survey.questions.map(function (question) { return ({
        id: question.id,
        question: question.question,
        response: getSurveyResponseValue(responses, question.id),
    }); }), _b[posthog_surveys_types_1.SurveyEventProperties.SURVEY_SUBMISSION_ID] = surveySubmissionId, _b[posthog_surveys_types_1.SurveyEventProperties.SURVEY_COMPLETED] = isSurveyCompleted, _b.sessionRecordingUrl = (_d = posthog.get_session_replay_url) === null || _d === void 0 ? void 0 : _d.call(posthog), _b), responses), { $set: (_c = {},
            _c[(0, survey_utils_1.getSurveyInteractionProperty)(survey, 'responded')] = true,
            _c) }));
    if (isSurveyCompleted) {
        // Only dispatch PHSurveySent if the survey is completed, as that removes the survey from focus
        window.dispatchEvent(new CustomEvent('PHSurveySent', { detail: { surveyId: survey.id } }));
        (0, exports.clearInProgressSurveyState)(survey);
    }
};
exports.sendSurveyEvent = sendSurveyEvent;
var dismissedSurveyEvent = function (survey, posthog, readOnly) {
    var _a, _b, _c;
    var _d;
    if (!posthog) {
        survey_utils_1.SURVEY_LOGGER.error('[survey dismissed] event not captured, PostHog instance not found.');
        return;
    }
    if (readOnly) {
        return;
    }
    var inProgressSurvey = (0, exports.getInProgressSurveyState)(survey);
    posthog.capture(posthog_surveys_types_1.SurveyEventName.DISMISSED, __assign(__assign((_a = {}, _a[posthog_surveys_types_1.SurveyEventProperties.SURVEY_NAME] = survey.name, _a[posthog_surveys_types_1.SurveyEventProperties.SURVEY_ID] = survey.id, _a[posthog_surveys_types_1.SurveyEventProperties.SURVEY_ITERATION] = survey.current_iteration, _a[posthog_surveys_types_1.SurveyEventProperties.SURVEY_ITERATION_START_DATE] = survey.current_iteration_start_date, _a[posthog_surveys_types_1.SurveyEventProperties.SURVEY_PARTIALLY_COMPLETED] = Object.values((inProgressSurvey === null || inProgressSurvey === void 0 ? void 0 : inProgressSurvey.responses) || {}).filter(function (resp) { return !(0, core_1.isNullish)(resp); }).length > 0, _a.sessionRecordingUrl = (_d = posthog.get_session_replay_url) === null || _d === void 0 ? void 0 : _d.call(posthog), _a), inProgressSurvey === null || inProgressSurvey === void 0 ? void 0 : inProgressSurvey.responses), (_b = {}, _b[posthog_surveys_types_1.SurveyEventProperties.SURVEY_SUBMISSION_ID] = inProgressSurvey === null || inProgressSurvey === void 0 ? void 0 : inProgressSurvey.surveySubmissionId, _b[posthog_surveys_types_1.SurveyEventProperties.SURVEY_QUESTIONS] = survey.questions.map(function (question) { return ({
        id: question.id,
        question: question.question,
        response: getSurveyResponseValue((inProgressSurvey === null || inProgressSurvey === void 0 ? void 0 : inProgressSurvey.responses) || {}, question.id),
    }); }), _b.$set = (_c = {},
        _c[(0, survey_utils_1.getSurveyInteractionProperty)(survey, 'dismissed')] = true,
        _c), _b)));
    // Clear in-progress state on dismissal
    (0, exports.clearInProgressSurveyState)(survey);
    (0, survey_utils_1.setSurveySeenOnLocalStorage)(survey);
    window.dispatchEvent(new CustomEvent('PHSurveyClosed', { detail: { surveyId: survey.id } }));
};
exports.dismissedSurveyEvent = dismissedSurveyEvent;
// Use the Fisher-yates algorithm to shuffle this array
// https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
var shuffle = function (array) {
    return array
        .map(function (a) { return ({ sort: Math.floor(Math.random() * 10), value: a }); })
        .sort(function (a, b) { return a.sort - b.sort; })
        .map(function (a) { return a.value; });
};
exports.shuffle = shuffle;
var reverseIfUnshuffled = function (unshuffled, shuffled) {
    if (unshuffled.length === shuffled.length && unshuffled.every(function (val, index) { return val === shuffled[index]; })) {
        return shuffled.reverse();
    }
    return shuffled;
};
var getDisplayOrderChoices = function (question) {
    if (!question.shuffleOptions) {
        return question.choices;
    }
    var displayOrderChoices = question.choices;
    var openEndedChoice = '';
    if (question.hasOpenChoice) {
        // if the question has an open-ended choice, its always the last element in the choices array.
        openEndedChoice = displayOrderChoices.pop();
    }
    var shuffledOptions = reverseIfUnshuffled(displayOrderChoices, (0, exports.shuffle)(displayOrderChoices));
    if (question.hasOpenChoice) {
        question.choices.push(openEndedChoice);
        shuffledOptions.push(openEndedChoice);
    }
    return shuffledOptions;
};
exports.getDisplayOrderChoices = getDisplayOrderChoices;
var getDisplayOrderQuestions = function (survey) {
    if (!survey.appearance || !survey.appearance.shuffleQuestions || survey.enable_partial_responses) {
        return survey.questions;
    }
    return reverseIfUnshuffled(survey.questions, (0, exports.shuffle)(survey.questions));
};
exports.getDisplayOrderQuestions = getDisplayOrderQuestions;
var hasEvents = function (survey) {
    var _a, _b, _c, _d, _e, _f;
    return ((_c = (_b = (_a = survey.conditions) === null || _a === void 0 ? void 0 : _a.events) === null || _b === void 0 ? void 0 : _b.values) === null || _c === void 0 ? void 0 : _c.length) != undefined && ((_f = (_e = (_d = survey.conditions) === null || _d === void 0 ? void 0 : _d.events) === null || _e === void 0 ? void 0 : _e.values) === null || _f === void 0 ? void 0 : _f.length) > 0;
};
exports.hasEvents = hasEvents;
var canActivateRepeatedly = function (survey) {
    var _a, _b;
    return (!!(((_b = (_a = survey.conditions) === null || _a === void 0 ? void 0 : _a.events) === null || _b === void 0 ? void 0 : _b.repeatedActivation) && (0, exports.hasEvents)(survey)) ||
        survey.schedule === posthog_surveys_types_1.SurveySchedule.Always ||
        (0, exports.isSurveyInProgress)(survey));
};
exports.canActivateRepeatedly = canActivateRepeatedly;
/**
 * getSurveySeen checks local storage for the surveySeen Key a
 * and overrides this value if the survey can be repeatedly activated by its events.
 * @param survey
 */
var getSurveySeen = function (survey) {
    var surveySeen = localStorage.getItem((0, survey_utils_1.getSurveySeenKey)(survey));
    if (surveySeen) {
        // if a survey has already been seen,
        // we will override it with the event repeated activation value.
        return !(0, exports.canActivateRepeatedly)(survey);
    }
    return false;
};
exports.getSurveySeen = getSurveySeen;
var LAST_SEEN_SURVEY_DATE_KEY = 'lastSeenSurveyDate';
var hasWaitPeriodPassed = function (waitPeriodInDays) {
    var lastSeenSurveyDate = localStorage.getItem(LAST_SEEN_SURVEY_DATE_KEY);
    if (!waitPeriodInDays || !lastSeenSurveyDate) {
        return true;
    }
    var today = new Date();
    var diff = Math.abs(today.getTime() - new Date(lastSeenSurveyDate).getTime());
    var diffDaysFromToday = Math.ceil(diff / (1000 * 3600 * 24));
    return diffDaysFromToday > waitPeriodInDays;
};
exports.hasWaitPeriodPassed = hasWaitPeriodPassed;
exports.SurveyContext = (0, preact_1.createContext)({
    isPreviewMode: false,
    previewPageIndex: 0,
    onPopupSurveyDismissed: function () { },
    isPopup: true,
    onPreviewSubmit: function () { },
    surveySubmissionId: '',
});
var useSurveyContext = function () {
    return (0, hooks_1.useContext)(exports.SurveyContext);
};
exports.useSurveyContext = useSurveyContext;
var renderChildrenAsTextOrHtml = function (_a) {
    var component = _a.component, children = _a.children, renderAsHtml = _a.renderAsHtml, style = _a.style;
    return renderAsHtml
        ? (0, preact_1.cloneElement)(component, {
            dangerouslySetInnerHTML: { __html: children },
            style: style,
        })
        : (0, preact_1.cloneElement)(component, {
            children: children,
            style: style,
        });
};
exports.renderChildrenAsTextOrHtml = renderChildrenAsTextOrHtml;
function defaultMatchType(matchType) {
    return matchType !== null && matchType !== void 0 ? matchType : 'icontains';
}
// use urlMatchType to validate url condition, fallback to contains for backwards compatibility
function doesSurveyUrlMatch(survey) {
    var _a, _b, _c;
    if (!((_a = survey.conditions) === null || _a === void 0 ? void 0 : _a.url)) {
        return true;
    }
    // if we dont know the url, assume it is not a match
    var href = (_b = window === null || window === void 0 ? void 0 : window.location) === null || _b === void 0 ? void 0 : _b.href;
    if (!href) {
        return false;
    }
    var targets = [survey.conditions.url];
    var matchType = defaultMatchType((_c = survey.conditions) === null || _c === void 0 ? void 0 : _c.urlMatchType);
    return property_utils_1.propertyComparisons[matchType](targets, [href]);
}
function doesSurveyDeviceTypesMatch(survey) {
    var _a, _b, _c;
    if (!((_a = survey.conditions) === null || _a === void 0 ? void 0 : _a.deviceTypes) || ((_b = survey.conditions) === null || _b === void 0 ? void 0 : _b.deviceTypes.length) === 0) {
        return true;
    }
    // if we dont know the device type, assume it is not a match
    if (!globals_1.userAgent) {
        return false;
    }
    var deviceType = (0, user_agent_utils_1.detectDeviceType)(globals_1.userAgent);
    return property_utils_1.propertyComparisons[defaultMatchType((_c = survey.conditions) === null || _c === void 0 ? void 0 : _c.deviceTypesMatchType)](survey.conditions.deviceTypes, [deviceType]);
}
function doesSurveyMatchSelector(survey) {
    var _a;
    if (!((_a = survey.conditions) === null || _a === void 0 ? void 0 : _a.selector)) {
        return true;
    }
    return !!(document === null || document === void 0 ? void 0 : document.querySelector(survey.conditions.selector));
}
var getInProgressSurveyStateKey = function (survey) {
    var key = "".concat(survey_utils_1.SURVEY_IN_PROGRESS_PREFIX).concat(survey.id);
    if (survey.current_iteration && survey.current_iteration > 0) {
        key = "".concat(survey_utils_1.SURVEY_IN_PROGRESS_PREFIX).concat(survey.id, "_").concat(survey.current_iteration);
    }
    return key;
};
var setInProgressSurveyState = function (survey, state) {
    try {
        localStorage.setItem(getInProgressSurveyStateKey(survey), JSON.stringify(state));
    }
    catch (e) {
        survey_utils_1.SURVEY_LOGGER.error('Error setting in-progress survey state in localStorage', e);
    }
};
exports.setInProgressSurveyState = setInProgressSurveyState;
var getInProgressSurveyState = function (survey) {
    try {
        var stateString = localStorage.getItem(getInProgressSurveyStateKey(survey));
        if (stateString) {
            return JSON.parse(stateString);
        }
    }
    catch (e) {
        survey_utils_1.SURVEY_LOGGER.error('Error getting in-progress survey state from localStorage', e);
    }
    return null;
};
exports.getInProgressSurveyState = getInProgressSurveyState;
var isSurveyInProgress = function (survey) {
    var state = (0, exports.getInProgressSurveyState)(survey);
    return !(0, core_1.isNullish)(state === null || state === void 0 ? void 0 : state.surveySubmissionId);
};
exports.isSurveyInProgress = isSurveyInProgress;
var clearInProgressSurveyState = function (survey) {
    try {
        localStorage.removeItem(getInProgressSurveyStateKey(survey));
    }
    catch (e) {
        survey_utils_1.SURVEY_LOGGER.error('Error clearing in-progress survey state from localStorage', e);
    }
};
exports.clearInProgressSurveyState = clearInProgressSurveyState;
function getSurveyContainerClass(survey, asSelector) {
    if (asSelector === void 0) { asSelector = false; }
    var className = "PostHogSurvey-".concat(survey.id);
    return asSelector ? ".".concat(className) : className;
}
//# sourceMappingURL=surveys-extension-utils.jsx.map