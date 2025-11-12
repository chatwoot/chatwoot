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
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.renderFeedbackWidgetPreview = exports.renderSurveysPreview = exports.SurveyManager = void 0;
exports.getNextSurveyStep = getNextSurveyStep;
exports.generateSurveys = generateSurveys;
exports.useHideSurveyOnURLChange = useHideSurveyOnURLChange;
exports.usePopupVisibility = usePopupVisibility;
exports.SurveyPopup = SurveyPopup;
exports.Questions = Questions;
exports.FeedbackWidget = FeedbackWidget;
var Preact = __importStar(require("preact"));
var hooks_1 = require("preact/hooks");
var posthog_surveys_types_1 = require("../posthog-surveys-types");
var utils_1 = require("../utils");
var globals_1 = require("../utils/globals");
var survey_utils_1 = require("../utils/survey-utils");
var core_1 = require("@posthog/core");
var uuidv7_1 = require("../uuidv7");
var ConfirmationMessage_1 = require("./surveys/components/ConfirmationMessage");
var QuestionHeader_1 = require("./surveys/components/QuestionHeader");
var QuestionTypes_1 = require("./surveys/components/QuestionTypes");
var surveys_extension_utils_1 = require("./surveys/surveys-extension-utils");
// We cast the types here which is dangerous but protected by the top level generateSurveys call
var window = globals_1.window;
var document = globals_1.document;
var DISPATCH_FEEDBACK_WIDGET_EVENT = 'ph:show_survey_widget';
var WIDGET_LISTENER_ATTRIBUTE = 'PHWidgetSurveyClickListener';
function getRatingBucketForResponseValue(responseValue, scale) {
    if (scale === 3) {
        if (responseValue < 1 || responseValue > 3) {
            throw new Error('The response must be in range 1-3');
        }
        return responseValue === 1 ? 'negative' : responseValue === 2 ? 'neutral' : 'positive';
    }
    else if (scale === 5) {
        if (responseValue < 1 || responseValue > 5) {
            throw new Error('The response must be in range 1-5');
        }
        return responseValue <= 2 ? 'negative' : responseValue === 3 ? 'neutral' : 'positive';
    }
    else if (scale === 7) {
        if (responseValue < 1 || responseValue > 7) {
            throw new Error('The response must be in range 1-7');
        }
        return responseValue <= 3 ? 'negative' : responseValue === 4 ? 'neutral' : 'positive';
    }
    else if (scale === 10) {
        if (responseValue < 0 || responseValue > 10) {
            throw new Error('The response must be in range 0-10');
        }
        return responseValue <= 6 ? 'detractors' : responseValue <= 8 ? 'passives' : 'promoters';
    }
    throw new Error('The scale must be one of: 3, 5, 7, 10');
}
function getNextSurveyStep(survey, currentQuestionIndex, response) {
    var _a, _b, _c, _d, _e;
    var question = survey.questions[currentQuestionIndex];
    var nextQuestionIndex = currentQuestionIndex + 1;
    if (!((_a = question.branching) === null || _a === void 0 ? void 0 : _a.type)) {
        if (currentQuestionIndex === survey.questions.length - 1) {
            return posthog_surveys_types_1.SurveyQuestionBranchingType.End;
        }
        return nextQuestionIndex;
    }
    if (question.branching.type === posthog_surveys_types_1.SurveyQuestionBranchingType.End) {
        return posthog_surveys_types_1.SurveyQuestionBranchingType.End;
    }
    else if (question.branching.type === posthog_surveys_types_1.SurveyQuestionBranchingType.SpecificQuestion) {
        if (Number.isInteger(question.branching.index)) {
            return question.branching.index;
        }
    }
    else if (question.branching.type === posthog_surveys_types_1.SurveyQuestionBranchingType.ResponseBased) {
        // Single choice
        if (question.type === posthog_surveys_types_1.SurveyQuestionType.SingleChoice) {
            // :KLUDGE: for now, look up the choiceIndex based on the response
            // TODO: once QuestionTypes.MultipleChoiceQuestion is refactored, pass the selected choiceIndex into this method
            var selectedChoiceIndex = question.choices.indexOf("".concat(response));
            if (selectedChoiceIndex === -1 && question.hasOpenChoice) {
                // if the response is not found in the choices, it must be the open choice,
                // which is always the last choice
                selectedChoiceIndex = question.choices.length - 1;
            }
            if ((_c = (_b = question.branching) === null || _b === void 0 ? void 0 : _b.responseValues) === null || _c === void 0 ? void 0 : _c.hasOwnProperty(selectedChoiceIndex)) {
                var nextStep = question.branching.responseValues[selectedChoiceIndex];
                // Specific question
                if (Number.isInteger(nextStep)) {
                    return nextStep;
                }
                if (nextStep === posthog_surveys_types_1.SurveyQuestionBranchingType.End) {
                    return posthog_surveys_types_1.SurveyQuestionBranchingType.End;
                }
                return nextQuestionIndex;
            }
        }
        else if (question.type === posthog_surveys_types_1.SurveyQuestionType.Rating) {
            if (typeof response !== 'number' || !Number.isInteger(response)) {
                throw new Error('The response type must be an integer');
            }
            var ratingBucket = getRatingBucketForResponseValue(response, question.scale);
            if ((_e = (_d = question.branching) === null || _d === void 0 ? void 0 : _d.responseValues) === null || _e === void 0 ? void 0 : _e.hasOwnProperty(ratingBucket)) {
                var nextStep = question.branching.responseValues[ratingBucket];
                // Specific question
                if (Number.isInteger(nextStep)) {
                    return nextStep;
                }
                if (nextStep === posthog_surveys_types_1.SurveyQuestionBranchingType.End) {
                    return posthog_surveys_types_1.SurveyQuestionBranchingType.End;
                }
                return nextQuestionIndex;
            }
        }
        return nextQuestionIndex;
    }
    survey_utils_1.SURVEY_LOGGER.warn('Falling back to next question index due to unexpected branching type');
    return nextQuestionIndex;
}
var SURVEY_NEXT_TO_TRIGGER_PARAMS = {
    ESTIMATED_MIN_HEIGHT: 250,
    HORIZONTAL_PADDING: 20,
    TRIGGER_SPACING: 12,
};
function getNextToTriggerPosition(target, surveyWidth) {
    try {
        var buttonRect = target.getBoundingClientRect();
        var viewportHeight = window.innerHeight;
        var viewportWidth = window.innerWidth;
        var estimatedMinSurveyHeight = SURVEY_NEXT_TO_TRIGGER_PARAMS.ESTIMATED_MIN_HEIGHT;
        var buttonCenterX = buttonRect.left + buttonRect.width / 2;
        var left = buttonCenterX - surveyWidth / 2;
        var horizontalPadding = SURVEY_NEXT_TO_TRIGGER_PARAMS.HORIZONTAL_PADDING;
        if (left + surveyWidth > viewportWidth - horizontalPadding) {
            left = viewportWidth - surveyWidth - horizontalPadding;
        }
        if (left < horizontalPadding) {
            left = horizontalPadding;
        }
        var spacing = SURVEY_NEXT_TO_TRIGGER_PARAMS.TRIGGER_SPACING;
        var spaceBelow = viewportHeight - buttonRect.bottom;
        var spaceAbove = buttonRect.top;
        var showAbove = spaceBelow < estimatedMinSurveyHeight && spaceAbove > spaceBelow;
        return {
            position: 'fixed',
            top: showAbove ? 'auto' : "".concat(buttonRect.bottom + spacing, "px"),
            left: "".concat(left, "px"),
            right: 'auto',
            bottom: showAbove ? "".concat(viewportHeight - buttonRect.top + spacing, "px") : 'auto',
            zIndex: surveys_extension_utils_1.defaultSurveyAppearance.zIndex,
        };
    }
    catch (error) {
        survey_utils_1.SURVEY_LOGGER.warn('Failed to calculate trigger position:', error);
        return null;
    }
}
// Keep in sync with posthog/constants.py on main repo
var SURVEY_TARGETING_FLAG_PREFIX = 'survey-targeting-';
var SurveyManager = /** @class */ (function () {
    function SurveyManager(posthog) {
        var _this = this;
        this._surveyTimeouts = new Map();
        this._widgetSelectorListeners = new Map();
        this._handlePopoverSurvey = function (survey) {
            var _a;
            _this._clearSurveyTimeout(survey.id);
            _this._addSurveyToFocus(survey);
            var delaySeconds = ((_a = survey.appearance) === null || _a === void 0 ? void 0 : _a.surveyPopupDelaySeconds) || 0;
            var shadow = (0, surveys_extension_utils_1.retrieveSurveyShadow)(survey, _this._posthog).shadow;
            if (delaySeconds <= 0) {
                return Preact.render(<SurveyPopup posthog={_this._posthog} survey={survey} removeSurveyFromFocus={_this._removeSurveyFromFocus}/>, shadow);
            }
            var timeoutId = setTimeout(function () {
                if (!(0, surveys_extension_utils_1.doesSurveyUrlMatch)(survey)) {
                    return _this._removeSurveyFromFocus(survey);
                }
                // rendering with surveyPopupDelaySeconds = 0 because we're already handling the timeout here
                Preact.render(<SurveyPopup posthog={_this._posthog} survey={__assign(__assign({}, survey), { appearance: __assign(__assign({}, survey.appearance), { surveyPopupDelaySeconds: 0 }) })} removeSurveyFromFocus={_this._removeSurveyFromFocus}/>, shadow);
            }, delaySeconds * 1000);
            _this._surveyTimeouts.set(survey.id, timeoutId);
        };
        this._handleWidget = function (survey) {
            // Ensure widget container exists if it doesn't
            var _a = (0, surveys_extension_utils_1.retrieveSurveyShadow)(survey, _this._posthog), shadow = _a.shadow, isNewlyCreated = _a.isNewlyCreated;
            // If the widget is already rendered, do nothing. Otherwise the widget will be re-rendered every second
            if (!isNewlyCreated) {
                return;
            }
            Preact.render(<FeedbackWidget posthog={_this._posthog} survey={survey} key={survey.id}/>, shadow);
        };
        this._removeWidgetSelectorListener = function (survey) {
            _this._removeSurveyFromDom(survey);
            var existing = _this._widgetSelectorListeners.get(survey.id);
            if (existing) {
                existing.element.removeEventListener('click', existing.listener);
                existing.element.removeAttribute(WIDGET_LISTENER_ATTRIBUTE);
                _this._widgetSelectorListeners.delete(survey.id);
                survey_utils_1.SURVEY_LOGGER.info("Removed click listener for survey ".concat(survey.id));
            }
        };
        this._manageWidgetSelectorListener = function (survey, selector) {
            var currentElement = document.querySelector(selector);
            var existingListenerData = _this._widgetSelectorListeners.get(survey.id);
            if (!currentElement) {
                if (existingListenerData) {
                    _this._removeWidgetSelectorListener(survey);
                }
                return;
            }
            _this._handleWidget(survey);
            if (existingListenerData) {
                // Listener exists, check if element changed
                if (currentElement !== existingListenerData.element) {
                    survey_utils_1.SURVEY_LOGGER.info("Selector element changed for survey ".concat(survey.id, ". Re-attaching listener."));
                    _this._removeWidgetSelectorListener(survey);
                    // Continue to attach listener to the new element below
                }
                else {
                    // Element is the same, listener already attached, do nothing
                    return;
                }
            }
            // Element found, and no listener attached (or it was just removed from old element)
            if (!currentElement.hasAttribute(WIDGET_LISTENER_ATTRIBUTE)) {
                var listener = function (event) {
                    var _a, _b;
                    event.stopPropagation(); // Prevent bubbling
                    var positionStyles = ((_a = survey.appearance) === null || _a === void 0 ? void 0 : _a.position) === posthog_surveys_types_1.SurveyPosition.NextToTrigger
                        ? getNextToTriggerPosition(event.currentTarget, parseInt(((_b = survey.appearance) === null || _b === void 0 ? void 0 : _b.maxWidth) || surveys_extension_utils_1.defaultSurveyAppearance.maxWidth))
                        : {};
                    window.dispatchEvent(new CustomEvent(DISPATCH_FEEDBACK_WIDGET_EVENT, {
                        detail: { surveyId: survey.id, position: positionStyles },
                    }));
                };
                (0, utils_1.addEventListener)(currentElement, 'click', listener);
                currentElement.setAttribute(WIDGET_LISTENER_ATTRIBUTE, 'true');
                _this._widgetSelectorListeners.set(survey.id, { element: currentElement, listener: listener, survey: survey });
                survey_utils_1.SURVEY_LOGGER.info("Attached click listener for feedback button survey ".concat(survey.id));
            }
        };
        this.renderSurvey = function (survey, selector) {
            Preact.render(<SurveyPopup posthog={_this._posthog} survey={survey} removeSurveyFromFocus={_this._removeSurveyFromFocus} isPopup={false}/>, selector);
        };
        this.getActiveMatchingSurveys = function (callback, forceReload) {
            var _a;
            if (forceReload === void 0) { forceReload = false; }
            (_a = _this._posthog) === null || _a === void 0 ? void 0 : _a.surveys.getSurveys(function (surveys) {
                var targetingMatchedSurveys = surveys.filter(function (survey) {
                    var eligibility = _this.checkSurveyEligibility(survey);
                    return (eligibility.eligible &&
                        _this._isSurveyConditionMatched(survey) &&
                        _this._hasActionOrEventTriggeredSurvey(survey) &&
                        _this._checkFlags(survey));
                });
                callback(targetingMatchedSurveys);
            }, forceReload);
        };
        this.callSurveysAndEvaluateDisplayLogic = function (forceReload) {
            if (forceReload === void 0) { forceReload = false; }
            _this.getActiveMatchingSurveys(function (surveys) {
                var inAppSurveysWithDisplayLogic = surveys.filter(function (survey) { return survey.type === posthog_surveys_types_1.SurveyType.Popover || survey.type === posthog_surveys_types_1.SurveyType.Widget; });
                // Create a queue of surveys sorted by their appearance delay.  We will evaluate the display logic
                // for each survey in the queue in order, and only display one survey at a time.
                var inAppSurveysQueue = _this._sortSurveysByAppearanceDelay(inAppSurveysWithDisplayLogic);
                // Keep track of surveys processed this cycle to remove listeners for inactive ones
                var activeSelectorSurveys = new Set();
                inAppSurveysQueue.forEach(function (survey) {
                    var _a, _b, _c, _d;
                    // Widget Type Logic
                    if (survey.type === posthog_surveys_types_1.SurveyType.Widget) {
                        if (((_a = survey.appearance) === null || _a === void 0 ? void 0 : _a.widgetType) === posthog_surveys_types_1.SurveyWidgetType.Tab) {
                            _this._handleWidget(survey);
                            return;
                        }
                        // For selector widget types, we need to manage the listener attachment/detachment dynamically
                        if (((_b = survey.appearance) === null || _b === void 0 ? void 0 : _b.widgetType) === posthog_surveys_types_1.SurveyWidgetType.Selector &&
                            ((_c = survey.appearance) === null || _c === void 0 ? void 0 : _c.widgetSelector)) {
                            activeSelectorSurveys.add(survey.id);
                            _this._manageWidgetSelectorListener(survey, (_d = survey.appearance) === null || _d === void 0 ? void 0 : _d.widgetSelector);
                        }
                    }
                    // Popover Type Logic (only one shown at a time)
                    if ((0, core_1.isNull)(_this._surveyInFocus) && survey.type === posthog_surveys_types_1.SurveyType.Popover) {
                        _this._handlePopoverSurvey(survey);
                    }
                });
                // Clean up listeners for surveys that are no longer active or matched
                _this._widgetSelectorListeners.forEach(function (_a) {
                    var survey = _a.survey;
                    if (!activeSelectorSurveys.has(survey.id)) {
                        _this._removeWidgetSelectorListener(survey);
                    }
                });
            }, forceReload);
        };
        this._addSurveyToFocus = function (survey) {
            if (!(0, core_1.isNull)(_this._surveyInFocus)) {
                survey_utils_1.SURVEY_LOGGER.error("Survey ".concat(__spreadArray([], __read(_this._surveyInFocus), false), " already in focus. Cannot add survey ").concat(survey.id, "."));
            }
            _this._surveyInFocus = survey.id;
        };
        this._removeSurveyFromFocus = function (survey) {
            if (_this._surveyInFocus !== survey.id) {
                survey_utils_1.SURVEY_LOGGER.error("Survey ".concat(survey.id, " is not in focus. Cannot remove survey ").concat(survey.id, "."));
            }
            _this._clearSurveyTimeout(survey.id);
            _this._surveyInFocus = null;
            _this._removeSurveyFromDom(survey);
        };
        this._posthog = posthog;
        // This is used to track the survey that is currently in focus. We only show one survey at a time.
        this._surveyInFocus = null;
    }
    SurveyManager.prototype._clearSurveyTimeout = function (surveyId) {
        var timeout = this._surveyTimeouts.get(surveyId);
        if (timeout) {
            clearTimeout(timeout);
            this._surveyTimeouts.delete(surveyId);
        }
    };
    /**
     * Sorts surveys by their appearance delay in ascending order. If a survey does not have an appearance delay,
     * it is considered to have a delay of 0.
     * @param surveys
     * @returns The surveys sorted by their appearance delay
     */
    SurveyManager.prototype._sortSurveysByAppearanceDelay = function (surveys) {
        return surveys.sort(function (a, b) {
            var _a, _b;
            var isSurveyInProgressA = (0, surveys_extension_utils_1.isSurveyInProgress)(a);
            var isSurveyInProgressB = (0, surveys_extension_utils_1.isSurveyInProgress)(b);
            if (isSurveyInProgressA && !isSurveyInProgressB) {
                return -1; // a comes before b (in progress surveys first)
            }
            if (!isSurveyInProgressA && isSurveyInProgressB) {
                return 1; // a comes after b (in progress surveys first)
            }
            var aIsAlways = a.schedule === posthog_surveys_types_1.SurveySchedule.Always;
            var bIsAlways = b.schedule === posthog_surveys_types_1.SurveySchedule.Always;
            if (aIsAlways && !bIsAlways) {
                return 1; // a comes after b
            }
            if (!aIsAlways && bIsAlways) {
                return -1; // a comes before b
            }
            // If both are Always or neither is Always, sort by delay
            return (((_a = a.appearance) === null || _a === void 0 ? void 0 : _a.surveyPopupDelaySeconds) || 0) - (((_b = b.appearance) === null || _b === void 0 ? void 0 : _b.surveyPopupDelaySeconds) || 0);
        });
    };
    SurveyManager.prototype._isSurveyFeatureFlagEnabled = function (flagKey, flagVariant) {
        if (flagVariant === void 0) { flagVariant = undefined; }
        if (!flagKey) {
            return true;
        }
        var isFeatureEnabled = !!this._posthog.featureFlags.isFeatureEnabled(flagKey, {
            send_event: !flagKey.startsWith(SURVEY_TARGETING_FLAG_PREFIX),
        });
        var flagVariantCheck = true;
        if (flagVariant) {
            var flagVariantValue = this._posthog.featureFlags.getFeatureFlag(flagKey, { send_event: false });
            flagVariantCheck = flagVariantValue === flagVariant || flagVariant === 'any';
        }
        return isFeatureEnabled && flagVariantCheck;
    };
    SurveyManager.prototype._isSurveyConditionMatched = function (survey) {
        if (!survey.conditions) {
            return true;
        }
        return (0, surveys_extension_utils_1.doesSurveyUrlMatch)(survey) && (0, surveys_extension_utils_1.doesSurveyDeviceTypesMatch)(survey) && (0, surveys_extension_utils_1.doesSurveyMatchSelector)(survey);
    };
    SurveyManager.prototype._internalFlagCheckSatisfied = function (survey) {
        return ((0, surveys_extension_utils_1.canActivateRepeatedly)(survey) ||
            this._isSurveyFeatureFlagEnabled(survey.internal_targeting_flag_key) ||
            (0, surveys_extension_utils_1.isSurveyInProgress)(survey));
    };
    SurveyManager.prototype.checkSurveyEligibility = function (survey) {
        var _a, _b;
        var eligibility = { eligible: true, reason: undefined };
        if (!(0, survey_utils_1.isSurveyRunning)(survey)) {
            eligibility.eligible = false;
            eligibility.reason = "Survey is not running. It was completed on ".concat(survey.end_date);
            return eligibility;
        }
        if (!survey_utils_1.IN_APP_SURVEY_TYPES.includes(survey.type)) {
            eligibility.eligible = false;
            eligibility.reason = "Surveys of type ".concat(survey.type, " are never eligible to be shown in the app");
            return eligibility;
        }
        var linkedFlagVariant = (_a = survey.conditions) === null || _a === void 0 ? void 0 : _a.linkedFlagVariant;
        if (!this._isSurveyFeatureFlagEnabled(survey.linked_flag_key, linkedFlagVariant)) {
            eligibility.eligible = false;
            if (!linkedFlagVariant) {
                eligibility.reason = "Survey linked feature flag is not enabled";
            }
            else {
                eligibility.reason = "Survey linked feature flag is not enabled for variant ".concat(linkedFlagVariant);
            }
            return eligibility;
        }
        if (!this._isSurveyFeatureFlagEnabled(survey.targeting_flag_key)) {
            eligibility.eligible = false;
            eligibility.reason = "Survey targeting feature flag is not enabled";
            return eligibility;
        }
        if (!this._internalFlagCheckSatisfied(survey)) {
            eligibility.eligible = false;
            eligibility.reason =
                'Survey internal targeting flag is not enabled and survey cannot activate repeatedly and survey is not in progress';
            return eligibility;
        }
        if (!(0, surveys_extension_utils_1.hasWaitPeriodPassed)((_b = survey.conditions) === null || _b === void 0 ? void 0 : _b.seenSurveyWaitPeriodInDays)) {
            eligibility.eligible = false;
            eligibility.reason = "Survey wait period has not passed";
            return eligibility;
        }
        if ((0, surveys_extension_utils_1.getSurveySeen)(survey)) {
            eligibility.eligible = false;
            eligibility.reason = "Survey has already been seen and it can't be activated again";
            return eligibility;
        }
        return eligibility;
    };
    /**
     * Surveys can be activated by events or actions. This method checks if the survey has events and actions,
     * and if so, it checks if the survey has been activated.
     * @param survey
     */
    SurveyManager.prototype._hasActionOrEventTriggeredSurvey = function (survey) {
        var _a;
        if (!(0, survey_utils_1.doesSurveyActivateByEvent)(survey) && !(0, survey_utils_1.doesSurveyActivateByAction)(survey)) {
            // If survey doesn't depend on events/actions, it's considered "triggered" by default
            return true;
        }
        var surveysActivatedByEventsOrActions = (_a = this._posthog.surveys._surveyEventReceiver) === null || _a === void 0 ? void 0 : _a.getSurveys();
        return !!(surveysActivatedByEventsOrActions === null || surveysActivatedByEventsOrActions === void 0 ? void 0 : surveysActivatedByEventsOrActions.includes(survey.id));
    };
    SurveyManager.prototype._checkFlags = function (survey) {
        var _this = this;
        var _a;
        if (!((_a = survey.feature_flag_keys) === null || _a === void 0 ? void 0 : _a.length)) {
            return true;
        }
        return survey.feature_flag_keys.every(function (_a) {
            var key = _a.key, value = _a.value;
            if (!key || !value) {
                return true;
            }
            return _this._isSurveyFeatureFlagEnabled(value);
        });
    };
    SurveyManager.prototype._removeSurveyFromDom = function (survey) {
        try {
            var shadowContainer = document.querySelector((0, surveys_extension_utils_1.getSurveyContainerClass)(survey, true));
            if (shadowContainer === null || shadowContainer === void 0 ? void 0 : shadowContainer.shadowRoot) {
                Preact.render(null, shadowContainer.shadowRoot);
            }
            shadowContainer === null || shadowContainer === void 0 ? void 0 : shadowContainer.remove();
        }
        catch (error) {
            survey_utils_1.SURVEY_LOGGER.warn("Failed to remove survey ".concat(survey.id, " from DOM:"), error);
        }
    };
    // Expose internal state and methods for testing
    SurveyManager.prototype.getTestAPI = function () {
        return {
            addSurveyToFocus: this._addSurveyToFocus,
            removeSurveyFromFocus: this._removeSurveyFromFocus,
            surveyInFocus: this._surveyInFocus,
            surveyTimeouts: this._surveyTimeouts,
            handleWidget: this._handleWidget,
            handlePopoverSurvey: this._handlePopoverSurvey,
            manageWidgetSelectorListener: this._manageWidgetSelectorListener,
            sortSurveysByAppearanceDelay: this._sortSurveysByAppearanceDelay,
            checkFlags: this._checkFlags.bind(this),
            isSurveyFeatureFlagEnabled: this._isSurveyFeatureFlagEnabled.bind(this),
        };
    };
    return SurveyManager;
}());
exports.SurveyManager = SurveyManager;
var DEFAULT_PREVIEW_POSITION_STYLES = {
    position: 'relative',
    left: 'unset',
    right: 'unset',
    top: 'unset',
    bottom: 'unset',
    transform: 'unset',
};
var renderSurveysPreview = function (_a) {
    var survey = _a.survey, parentElement = _a.parentElement, previewPageIndex = _a.previewPageIndex, forceDisableHtml = _a.forceDisableHtml, onPreviewSubmit = _a.onPreviewSubmit, _b = _a.positionStyles, positionStyles = _b === void 0 ? DEFAULT_PREVIEW_POSITION_STYLES : _b;
    var currentStyle = parentElement.querySelector('style[data-ph-survey-style]');
    if (currentStyle) {
        currentStyle.remove();
    }
    var stylesheet = (0, surveys_extension_utils_1.getSurveyStylesheet)();
    if (stylesheet) {
        parentElement.appendChild(stylesheet);
        (0, surveys_extension_utils_1.addSurveyCSSVariablesToElement)(parentElement, survey.type, survey.appearance);
    }
    Preact.render(<SurveyPopup survey={survey} forceDisableHtml={forceDisableHtml} style={positionStyles} onPreviewSubmit={onPreviewSubmit} previewPageIndex={previewPageIndex} removeSurveyFromFocus={function () { }}/>, parentElement);
};
exports.renderSurveysPreview = renderSurveysPreview;
var renderFeedbackWidgetPreview = function (_a) {
    var survey = _a.survey, root = _a.root, forceDisableHtml = _a.forceDisableHtml;
    var stylesheet = (0, surveys_extension_utils_1.getSurveyStylesheet)();
    if (stylesheet) {
        root.appendChild(stylesheet);
        (0, surveys_extension_utils_1.addSurveyCSSVariablesToElement)(root, survey.type, survey.appearance);
    }
    Preact.render(<FeedbackWidget forceDisableHtml={forceDisableHtml} survey={survey} readOnly={true}/>, root);
};
exports.renderFeedbackWidgetPreview = renderFeedbackWidgetPreview;
// This is the main exported function
function generateSurveys(posthog, isSurveysEnabled) {
    // NOTE: Important to ensure we never try and run surveys without a window environment
    if (!document || !window) {
        return;
    }
    var surveyManager = new SurveyManager(posthog);
    if (posthog.config.disable_surveys_automatic_display) {
        survey_utils_1.SURVEY_LOGGER.info('Surveys automatic display is disabled. Skipping call surveys and evaluate display logic.');
        return surveyManager;
    }
    // NOTE: The `generateSurveys` function used to accept just a single parameter, without any `isSurveysEnabled` parameter.
    // To keep compatibility with old clients, we'll consider `undefined` the same as `true`
    if (isSurveysEnabled === false) {
        survey_utils_1.SURVEY_LOGGER.info('There are no surveys to load or Surveys is disabled in the project settings.');
        return surveyManager;
    }
    surveyManager.callSurveysAndEvaluateDisplayLogic(true);
    // recalculate surveys every second to check if URL or selectors have changed
    setInterval(function () {
        surveyManager.callSurveysAndEvaluateDisplayLogic(false);
    }, 1000);
    return surveyManager;
}
/**
 * This hook handles URL-based survey visibility after the initial mount.
 * The initial URL check is handled by the `getActiveMatchingSurveys` method in  the `PostHogSurveys` class,
 * which ensures the URL matches before displaying a survey for the first time.
 * That is the method that is called every second to see if there's a matching survey.
 *
 * This separation of concerns means:
 * 1. Initial URL matching is done by `getActiveMatchingSurveys` before displaying the survey
 * 2. Subsequent URL changes are handled here to hide the survey as the user navigates
 */
function useHideSurveyOnURLChange(_a) {
    var survey = _a.survey, _b = _a.removeSurveyFromFocus, removeSurveyFromFocus = _b === void 0 ? function () { } : _b, setSurveyVisible = _a.setSurveyVisible, _c = _a.isPreviewMode, isPreviewMode = _c === void 0 ? false : _c;
    (0, hooks_1.useEffect)(function () {
        var _a;
        if (isPreviewMode || !((_a = survey.conditions) === null || _a === void 0 ? void 0 : _a.url)) {
            return;
        }
        var checkUrlMatch = function () {
            var _a;
            var isSurveyTypeWidget = survey.type === posthog_surveys_types_1.SurveyType.Widget;
            var doesSurveyMatchUrlCondition = (0, surveys_extension_utils_1.doesSurveyUrlMatch)(survey);
            var isSurveyWidgetTypeTab = ((_a = survey.appearance) === null || _a === void 0 ? void 0 : _a.widgetType) === posthog_surveys_types_1.SurveyWidgetType.Tab && isSurveyTypeWidget;
            if (doesSurveyMatchUrlCondition) {
                if (isSurveyWidgetTypeTab) {
                    survey_utils_1.SURVEY_LOGGER.info("Showing survey ".concat(survey.id, " because it is a feedback button tab and URL matches"));
                    setSurveyVisible(true);
                }
                return;
            }
            survey_utils_1.SURVEY_LOGGER.info("Hiding survey ".concat(survey.id, " because URL does not match"));
            setSurveyVisible(false);
            return removeSurveyFromFocus(survey);
        };
        // Listen for browser back/forward browser history changes
        (0, utils_1.addEventListener)(window, 'popstate', checkUrlMatch);
        // Listen for hash changes, for SPA frameworks that use hash-based routing
        // The hashchange event is fired when the fragment identifier of the URL has changed (the part of the URL beginning with and following the # symbol).
        (0, utils_1.addEventListener)(window, 'hashchange', checkUrlMatch);
        // Listen for SPA navigation
        var originalPushState = window.history.pushState;
        var originalReplaceState = window.history.replaceState;
        window.history.pushState = function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            originalPushState.apply(this, args);
            checkUrlMatch();
        };
        window.history.replaceState = function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            originalReplaceState.apply(this, args);
            checkUrlMatch();
        };
        return function () {
            window.removeEventListener('popstate', checkUrlMatch);
            window.removeEventListener('hashchange', checkUrlMatch);
            window.history.pushState = originalPushState;
            window.history.replaceState = originalReplaceState;
        };
    }, [isPreviewMode, survey, removeSurveyFromFocus, setSurveyVisible]);
}
function usePopupVisibility(survey, posthog, millisecondDelay, isPreviewMode, removeSurveyFromFocus, surveyContainerRef) {
    var _a = __read((0, hooks_1.useState)(isPreviewMode || millisecondDelay === 0), 2), isPopupVisible = _a[0], setIsPopupVisible = _a[1];
    var _b = __read((0, hooks_1.useState)(false), 2), isSurveySent = _b[0], setIsSurveySent = _b[1];
    var hidePopupWithViewTransition = function () {
        var removeDOMAndHidePopup = function () {
            if (survey.type === posthog_surveys_types_1.SurveyType.Popover) {
                removeSurveyFromFocus(survey);
            }
            setIsPopupVisible(false);
        };
        if (!document.startViewTransition) {
            removeDOMAndHidePopup();
            return;
        }
        var transition = document.startViewTransition(function () {
            var _a;
            (_a = surveyContainerRef === null || surveyContainerRef === void 0 ? void 0 : surveyContainerRef.current) === null || _a === void 0 ? void 0 : _a.remove();
        });
        transition.finished.then(function () {
            setTimeout(function () {
                removeDOMAndHidePopup();
            }, 100);
        });
    };
    var handleSurveyClosed = function (event) {
        if (event.detail.surveyId !== survey.id) {
            return;
        }
        hidePopupWithViewTransition();
    };
    (0, hooks_1.useEffect)(function () {
        if (!posthog) {
            survey_utils_1.SURVEY_LOGGER.error('usePopupVisibility hook called without a PostHog instance.');
            return;
        }
        if (isPreviewMode) {
            return;
        }
        var handleSurveySent = function (event) {
            var _a, _b;
            if (event.detail.surveyId !== survey.id) {
                return;
            }
            if (!((_a = survey.appearance) === null || _a === void 0 ? void 0 : _a.displayThankYouMessage)) {
                return hidePopupWithViewTransition();
            }
            setIsSurveySent(true);
            if ((_b = survey.appearance) === null || _b === void 0 ? void 0 : _b.autoDisappear) {
                setTimeout(function () {
                    hidePopupWithViewTransition();
                }, 5000);
            }
        };
        var showSurvey = function () {
            var _a;
            var _b;
            // check if the url is still matching, necessary for delayed surveys, as the URL may have changed
            if (!(0, surveys_extension_utils_1.doesSurveyUrlMatch)(survey)) {
                return;
            }
            setIsPopupVisible(true);
            window.dispatchEvent(new Event('PHSurveyShown'));
            posthog.capture(posthog_surveys_types_1.SurveyEventName.SHOWN, (_a = {},
                _a[posthog_surveys_types_1.SurveyEventProperties.SURVEY_NAME] = survey.name,
                _a[posthog_surveys_types_1.SurveyEventProperties.SURVEY_ID] = survey.id,
                _a[posthog_surveys_types_1.SurveyEventProperties.SURVEY_ITERATION] = survey.current_iteration,
                _a[posthog_surveys_types_1.SurveyEventProperties.SURVEY_ITERATION_START_DATE] = survey.current_iteration_start_date,
                _a.sessionRecordingUrl = (_b = posthog.get_session_replay_url) === null || _b === void 0 ? void 0 : _b.call(posthog),
                _a));
            localStorage.setItem('lastSeenSurveyDate', new Date().toISOString());
        };
        (0, utils_1.addEventListener)(window, 'PHSurveyClosed', handleSurveyClosed);
        (0, utils_1.addEventListener)(window, 'PHSurveySent', handleSurveySent);
        if (millisecondDelay > 0) {
            // This path is only used for direct usage of SurveyPopup,
            // not for surveys managed by SurveyManager
            var timeoutId_1 = setTimeout(showSurvey, millisecondDelay);
            return function () {
                clearTimeout(timeoutId_1);
                window.removeEventListener('PHSurveyClosed', handleSurveyClosed);
                window.removeEventListener('PHSurveySent', handleSurveySent);
            };
        }
        else {
            // This is the path used for surveys managed by SurveyManager
            showSurvey();
            return function () {
                window.removeEventListener('PHSurveyClosed', handleSurveyClosed);
                window.removeEventListener('PHSurveySent', handleSurveySent);
            };
        }
    }, []);
    useHideSurveyOnURLChange({
        survey: survey,
        removeSurveyFromFocus: removeSurveyFromFocus,
        setSurveyVisible: setIsPopupVisible,
        isPreviewMode: isPreviewMode,
    });
    return { isPopupVisible: isPopupVisible, isSurveySent: isSurveySent, setIsPopupVisible: setIsPopupVisible, hidePopupWithViewTransition: hidePopupWithViewTransition };
}
function getPopoverPosition(type, position, surveyWidgetType) {
    if (position === void 0) { position = posthog_surveys_types_1.SurveyPosition.Right; }
    switch (position) {
        case posthog_surveys_types_1.SurveyPosition.TopLeft:
            return { top: '0', left: '0', transform: 'translate(30px, 30px)' };
        case posthog_surveys_types_1.SurveyPosition.TopRight:
            return { top: '0', right: '0', transform: 'translate(-30px, 30px)' };
        case posthog_surveys_types_1.SurveyPosition.TopCenter:
            return { top: '0', left: '50%', transform: 'translate(-50%, 30px)' };
        case posthog_surveys_types_1.SurveyPosition.MiddleLeft:
            return { top: '50%', left: '0', transform: 'translate(30px, -50%)' };
        case posthog_surveys_types_1.SurveyPosition.MiddleRight:
            return { top: '50%', right: '0', transform: 'translate(-30px, -50%)' };
        case posthog_surveys_types_1.SurveyPosition.MiddleCenter:
            return { top: '50%', left: '50%', transform: 'translate(-50%, -50%)' };
        case posthog_surveys_types_1.SurveyPosition.Left:
            return { left: '30px' };
        case posthog_surveys_types_1.SurveyPosition.Center:
            return {
                left: '50%',
                transform: 'translateX(-50%)',
            };
        default:
        case posthog_surveys_types_1.SurveyPosition.Right:
            return { right: type === posthog_surveys_types_1.SurveyType.Widget && surveyWidgetType === posthog_surveys_types_1.SurveyWidgetType.Tab ? '60px' : '30px' };
    }
}
function SurveyPopup(_a) {
    var _b, _c, _d, _e, _f, _g;
    var survey = _a.survey, forceDisableHtml = _a.forceDisableHtml, posthog = _a.posthog, _h = _a.style, style = _h === void 0 ? {} : _h, previewPageIndex = _a.previewPageIndex, _j = _a.removeSurveyFromFocus, removeSurveyFromFocus = _j === void 0 ? function () { } : _j, _k = _a.isPopup, isPopup = _k === void 0 ? true : _k, _l = _a.onPreviewSubmit, onPreviewSubmit = _l === void 0 ? function () { } : _l, _m = _a.onPopupSurveyDismissed, onPopupSurveyDismissed = _m === void 0 ? function () { } : _m, _o = _a.onCloseConfirmationMessage, onCloseConfirmationMessage = _o === void 0 ? function () { } : _o;
    var surveyContainerRef = (0, hooks_1.useRef)(null);
    var isPreviewMode = Number.isInteger(previewPageIndex);
    // NB: The client-side code passes the millisecondDelay in seconds, but setTimeout expects milliseconds, so we multiply by 1000
    var surveyPopupDelayMilliseconds = ((_b = survey.appearance) === null || _b === void 0 ? void 0 : _b.surveyPopupDelaySeconds)
        ? survey.appearance.surveyPopupDelaySeconds * 1000
        : 0;
    var _p = usePopupVisibility(survey, posthog, surveyPopupDelayMilliseconds, isPreviewMode, removeSurveyFromFocus, surveyContainerRef), isPopupVisible = _p.isPopupVisible, isSurveySent = _p.isSurveySent, hidePopupWithViewTransition = _p.hidePopupWithViewTransition;
    var shouldShowConfirmation = isSurveySent || previewPageIndex === survey.questions.length;
    var surveyContextValue = (0, hooks_1.useMemo)(function () {
        var getInProgressSurvey = (0, surveys_extension_utils_1.getInProgressSurveyState)(survey);
        return {
            isPreviewMode: isPreviewMode,
            previewPageIndex: previewPageIndex,
            onPopupSurveyDismissed: function () {
                (0, surveys_extension_utils_1.dismissedSurveyEvent)(survey, posthog, isPreviewMode);
                onPopupSurveyDismissed();
            },
            isPopup: isPopup || false,
            surveySubmissionId: (getInProgressSurvey === null || getInProgressSurvey === void 0 ? void 0 : getInProgressSurvey.surveySubmissionId) || (0, uuidv7_1.uuidv7)(),
            onPreviewSubmit: onPreviewSubmit,
            posthog: posthog,
        };
    }, [isPreviewMode, previewPageIndex, isPopup, posthog, survey, onPopupSurveyDismissed, onPreviewSubmit]);
    if (!isPopupVisible) {
        return null;
    }
    return (<surveys_extension_utils_1.SurveyContext.Provider value={surveyContextValue}>
            <div className="ph-survey" style={__assign(__assign({}, getPopoverPosition(survey.type, (_c = survey.appearance) === null || _c === void 0 ? void 0 : _c.position, (_d = survey.appearance) === null || _d === void 0 ? void 0 : _d.widgetType)), style)} ref={surveyContainerRef}>
                {!shouldShowConfirmation ? (<Questions survey={survey} forceDisableHtml={!!forceDisableHtml} posthog={posthog}/>) : (<ConfirmationMessage_1.ConfirmationMessage header={((_e = survey.appearance) === null || _e === void 0 ? void 0 : _e.thankYouMessageHeader) || 'Thank you!'} description={((_f = survey.appearance) === null || _f === void 0 ? void 0 : _f.thankYouMessageDescription) || ''} forceDisableHtml={!!forceDisableHtml} contentType={(_g = survey.appearance) === null || _g === void 0 ? void 0 : _g.thankYouMessageDescriptionContentType} appearance={survey.appearance || surveys_extension_utils_1.defaultSurveyAppearance} onClose={function () {
                hidePopupWithViewTransition();
                onCloseConfirmationMessage();
            }}/>)}
            </div>
        </surveys_extension_utils_1.SurveyContext.Provider>);
}
function Questions(_a) {
    var survey = _a.survey, forceDisableHtml = _a.forceDisableHtml, posthog = _a.posthog;
    // Initialize responses from localStorage or empty object
    var _b = __read((0, hooks_1.useState)(function () {
        var inProgressSurveyData = (0, surveys_extension_utils_1.getInProgressSurveyState)(survey);
        if (inProgressSurveyData === null || inProgressSurveyData === void 0 ? void 0 : inProgressSurveyData.responses) {
            survey_utils_1.SURVEY_LOGGER.info('Survey is already in progress, filling in initial responses');
        }
        return (inProgressSurveyData === null || inProgressSurveyData === void 0 ? void 0 : inProgressSurveyData.responses) || {};
    }), 2), questionsResponses = _b[0], setQuestionsResponses = _b[1];
    var _c = (0, hooks_1.useContext)(surveys_extension_utils_1.SurveyContext), previewPageIndex = _c.previewPageIndex, onPopupSurveyDismissed = _c.onPopupSurveyDismissed, isPopup = _c.isPopup, onPreviewSubmit = _c.onPreviewSubmit, surveySubmissionId = _c.surveySubmissionId, isPreviewMode = _c.isPreviewMode;
    var _d = __read((0, hooks_1.useState)(function () {
        var inProgressSurveyData = (0, surveys_extension_utils_1.getInProgressSurveyState)(survey);
        return previewPageIndex || (inProgressSurveyData === null || inProgressSurveyData === void 0 ? void 0 : inProgressSurveyData.lastQuestionIndex) || 0;
    }), 2), currentQuestionIndex = _d[0], setCurrentQuestionIndex = _d[1];
    var surveyQuestions = (0, hooks_1.useMemo)(function () { return (0, surveys_extension_utils_1.getDisplayOrderQuestions)(survey); }, [survey]);
    // Sync preview state
    (0, hooks_1.useEffect)(function () {
        if (isPreviewMode && !(0, core_1.isUndefined)(previewPageIndex)) {
            setCurrentQuestionIndex(previewPageIndex);
        }
    }, [previewPageIndex, isPreviewMode]);
    var onNextButtonClick = function (_a) {
        var _b;
        var res = _a.res, displayQuestionIndex = _a.displayQuestionIndex, questionId = _a.questionId;
        if (!posthog) {
            survey_utils_1.SURVEY_LOGGER.error('onNextButtonClick called without a PostHog instance.');
            return;
        }
        if (!questionId) {
            survey_utils_1.SURVEY_LOGGER.error('onNextButtonClick called without a questionId.');
            return;
        }
        var responseKey = (0, surveys_extension_utils_1.getSurveyResponseKey)(questionId);
        var newResponses = __assign(__assign({}, questionsResponses), (_b = {}, _b[responseKey] = res, _b));
        setQuestionsResponses(newResponses);
        var nextStep = getNextSurveyStep(survey, displayQuestionIndex, res);
        var isSurveyCompleted = nextStep === posthog_surveys_types_1.SurveyQuestionBranchingType.End;
        if (!isSurveyCompleted) {
            setCurrentQuestionIndex(nextStep);
            (0, surveys_extension_utils_1.setInProgressSurveyState)(survey, {
                surveySubmissionId: surveySubmissionId,
                responses: newResponses,
                lastQuestionIndex: nextStep,
            });
        }
        // If partial responses are enabled, send the survey sent event with with the responses,
        // otherwise only send the event when the survey is completed
        if (survey.enable_partial_responses || isSurveyCompleted) {
            (0, surveys_extension_utils_1.sendSurveyEvent)({
                responses: newResponses,
                survey: survey,
                surveySubmissionId: surveySubmissionId,
                isSurveyCompleted: isSurveyCompleted,
                posthog: posthog,
            });
        }
    };
    var currentQuestion = surveyQuestions.at(currentQuestionIndex);
    if (!currentQuestion) {
        return null;
    }
    return (<form className="survey-form" name="surveyForm">
            {isPopup && (<QuestionHeader_1.Cancel onClick={function () {
                onPopupSurveyDismissed();
            }}/>)}
            <div className="survey-box">
                {getQuestionComponent({
            question: currentQuestion,
            forceDisableHtml: forceDisableHtml,
            displayQuestionIndex: currentQuestionIndex,
            appearance: survey.appearance || surveys_extension_utils_1.defaultSurveyAppearance,
            onSubmit: function (res) {
                return onNextButtonClick({
                    res: res,
                    displayQuestionIndex: currentQuestionIndex,
                    questionId: currentQuestion.id,
                });
            },
            onPreviewSubmit: onPreviewSubmit,
            initialValue: currentQuestion.id
                ? questionsResponses[(0, surveys_extension_utils_1.getSurveyResponseKey)(currentQuestion.id)]
                : undefined,
        })}
            </div>
        </form>);
}
function FeedbackWidget(_a) {
    var _b, _c, _d, _e, _f;
    var survey = _a.survey, forceDisableHtml = _a.forceDisableHtml, posthog = _a.posthog, readOnly = _a.readOnly;
    var _g = __read((0, hooks_1.useState)(true), 2), isFeedbackButtonVisible = _g[0], setIsFeedbackButtonVisible = _g[1];
    var _h = __read((0, hooks_1.useState)(false), 2), showSurvey = _h[0], setShowSurvey = _h[1];
    var _j = __read((0, hooks_1.useState)({}), 2), styleOverrides = _j[0], setStyleOverrides = _j[1];
    var toggleSurvey = function () {
        setShowSurvey(!showSurvey);
    };
    (0, hooks_1.useEffect)(function () {
        var _a;
        if (!posthog) {
            survey_utils_1.SURVEY_LOGGER.error('FeedbackWidget called without a PostHog instance.');
            return;
        }
        if (readOnly) {
            return;
        }
        if (((_a = survey.appearance) === null || _a === void 0 ? void 0 : _a.widgetType) === 'tab') {
            setStyleOverrides({
                top: '50%',
                bottom: 'auto',
            });
        }
        var handleShowSurvey = function (event) {
            var _a;
            var customEvent = event;
            // Check if the event is for this specific survey instance
            if (((_a = customEvent.detail) === null || _a === void 0 ? void 0 : _a.surveyId) === survey.id) {
                survey_utils_1.SURVEY_LOGGER.info("Received show event for feedback button survey ".concat(survey.id));
                setStyleOverrides(customEvent.detail.position || {});
                toggleSurvey();
            }
        };
        (0, utils_1.addEventListener)(window, DISPATCH_FEEDBACK_WIDGET_EVENT, handleShowSurvey);
        // Cleanup listener on component unmount
        return function () {
            window.removeEventListener(DISPATCH_FEEDBACK_WIDGET_EVENT, handleShowSurvey);
        };
    }, [
        posthog,
        readOnly,
        survey.id,
        (_b = survey.appearance) === null || _b === void 0 ? void 0 : _b.widgetType,
        (_c = survey.appearance) === null || _c === void 0 ? void 0 : _c.widgetSelector,
        (_d = survey.appearance) === null || _d === void 0 ? void 0 : _d.borderColor,
    ]);
    useHideSurveyOnURLChange({
        survey: survey,
        setSurveyVisible: setIsFeedbackButtonVisible,
    });
    if (!isFeedbackButtonVisible) {
        return null;
    }
    var resetShowSurvey = function () {
        // hide the feedback button after answering or closing the survey if it's not always show
        if (survey.schedule !== posthog_surveys_types_1.SurveySchedule.Always) {
            setIsFeedbackButtonVisible(false);
        }
        // important so our view transition has time to run
        setTimeout(function () {
            setShowSurvey(false);
        }, 200);
    };
    return (<Preact.Fragment>
            {((_e = survey.appearance) === null || _e === void 0 ? void 0 : _e.widgetType) === 'tab' && (<button className="ph-survey-widget-tab" onClick={toggleSurvey} disabled={readOnly}>
                    {((_f = survey.appearance) === null || _f === void 0 ? void 0 : _f.widgetLabel) || ''}
                </button>)}
            {showSurvey && (<SurveyPopup posthog={posthog} survey={survey} forceDisableHtml={forceDisableHtml} style={styleOverrides} onPopupSurveyDismissed={resetShowSurvey} onCloseConfirmationMessage={resetShowSurvey}/>)}
        </Preact.Fragment>);
}
var getQuestionComponent = function (_a) {
    var question = _a.question, forceDisableHtml = _a.forceDisableHtml, displayQuestionIndex = _a.displayQuestionIndex, appearance = _a.appearance, onSubmit = _a.onSubmit, onPreviewSubmit = _a.onPreviewSubmit, initialValue = _a.initialValue;
    var baseProps = {
        forceDisableHtml: forceDisableHtml,
        appearance: appearance,
        onPreviewSubmit: function (res) {
            onPreviewSubmit(res);
        },
        onSubmit: function (res) {
            onSubmit(res);
        },
        initialValue: initialValue,
        displayQuestionIndex: displayQuestionIndex,
    };
    switch (question.type) {
        case posthog_surveys_types_1.SurveyQuestionType.Open:
            return <QuestionTypes_1.OpenTextQuestion {...baseProps} question={question} key={question.id}/>;
        case posthog_surveys_types_1.SurveyQuestionType.Link:
            return <QuestionTypes_1.LinkQuestion {...baseProps} question={question} key={question.id}/>;
        case posthog_surveys_types_1.SurveyQuestionType.Rating:
            return <QuestionTypes_1.RatingQuestion {...baseProps} question={question} key={question.id}/>;
        case posthog_surveys_types_1.SurveyQuestionType.SingleChoice:
        case posthog_surveys_types_1.SurveyQuestionType.MultipleChoice:
            return <QuestionTypes_1.MultipleChoiceQuestion {...baseProps} question={question} key={question.id}/>;
        default:
            survey_utils_1.SURVEY_LOGGER.error("Unsupported question type: ".concat(question.type));
            return null;
    }
};
//# sourceMappingURL=surveys.jsx.map