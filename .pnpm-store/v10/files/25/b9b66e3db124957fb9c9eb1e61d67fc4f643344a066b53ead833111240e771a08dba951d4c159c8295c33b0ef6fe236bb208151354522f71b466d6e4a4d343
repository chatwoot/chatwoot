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
Object.defineProperty(exports, "__esModule", { value: true });
exports.OpenTextQuestion = OpenTextQuestion;
exports.LinkQuestion = LinkQuestion;
exports.RatingQuestion = RatingQuestion;
exports.RatingButton = RatingButton;
exports.MultipleChoiceQuestion = MultipleChoiceQuestion;
var preact_1 = require("preact");
var hooks_1 = require("preact/hooks");
var posthog_surveys_types_1 = require("../../../posthog-surveys-types");
var core_1 = require("@posthog/core");
var icons_1 = require("../icons");
var surveys_extension_utils_1 = require("../surveys-extension-utils");
var BottomSection_1 = require("./BottomSection");
var QuestionHeader_1 = require("./QuestionHeader");
var isValidStringArray = function (value) {
    return (0, core_1.isArray)(value) && value.every(function (item) { return (0, core_1.isString)(item); });
};
var initializeSelectedChoices = function (initialValue, questionType) {
    if ((0, core_1.isString)(initialValue)) {
        return initialValue;
    }
    if (isValidStringArray(initialValue)) {
        return initialValue;
    }
    return questionType === posthog_surveys_types_1.SurveyQuestionType.SingleChoice ? null : [];
};
var initializeOpenEndedState = function (initialValue, choices) {
    if ((0, core_1.isString)(initialValue) && !choices.includes(initialValue)) {
        return {
            isSelected: true,
            inputValue: initialValue,
        };
    }
    if (isValidStringArray(initialValue)) {
        var openEndedValue = initialValue.find(function (choice) { return !choices.includes(choice); });
        if (openEndedValue) {
            return {
                isSelected: true,
                inputValue: openEndedValue,
            };
        }
    }
    return {
        isSelected: false,
        inputValue: '',
    };
};
function OpenTextQuestion(_a) {
    var question = _a.question, forceDisableHtml = _a.forceDisableHtml, appearance = _a.appearance, onSubmit = _a.onSubmit, onPreviewSubmit = _a.onPreviewSubmit, displayQuestionIndex = _a.displayQuestionIndex, initialValue = _a.initialValue;
    var isPreviewMode = (0, surveys_extension_utils_1.useSurveyContext)().isPreviewMode;
    var inputRef = (0, hooks_1.useRef)(null);
    var _b = __read((0, hooks_1.useState)(function () {
        if ((0, core_1.isString)(initialValue)) {
            return initialValue;
        }
        return '';
    }), 2), text = _b[0], setText = _b[1];
    (0, hooks_1.useEffect)(function () {
        setTimeout(function () {
            var _a;
            if (!isPreviewMode) {
                (_a = inputRef.current) === null || _a === void 0 ? void 0 : _a.focus();
            }
        }, 100);
    }, [isPreviewMode]);
    var htmlFor = "surveyQuestion".concat(displayQuestionIndex);
    return (<preact_1.Fragment>
            <div className="question-container">
                <QuestionHeader_1.QuestionHeader question={question} forceDisableHtml={forceDisableHtml} htmlFor={htmlFor}/>
                <textarea ref={inputRef} id={htmlFor} rows={4} placeholder={appearance === null || appearance === void 0 ? void 0 : appearance.placeholder} onInput={function (e) {
            setText(e.currentTarget.value);
            e.stopPropagation();
        }} onKeyDown={function (e) {
            e.stopPropagation();
        }} value={text}/>
            </div>
            <BottomSection_1.BottomSection text={question.buttonText || 'Submit'} submitDisabled={!text && !question.optional} appearance={appearance} onSubmit={function () { return onSubmit(text); }} onPreviewSubmit={function () { return onPreviewSubmit(text); }}/>
        </preact_1.Fragment>);
}
function LinkQuestion(_a) {
    var question = _a.question, forceDisableHtml = _a.forceDisableHtml, appearance = _a.appearance, onSubmit = _a.onSubmit, onPreviewSubmit = _a.onPreviewSubmit;
    return (<preact_1.Fragment>
            <div className="question-container">
                <QuestionHeader_1.QuestionHeader question={question} forceDisableHtml={forceDisableHtml}/>
            </div>
            <BottomSection_1.BottomSection text={question.buttonText || 'Submit'} submitDisabled={false} link={question.link} appearance={appearance} onSubmit={function () { return onSubmit('link clicked'); }} onPreviewSubmit={function () { return onPreviewSubmit('link clicked'); }}/>
        </preact_1.Fragment>);
}
function RatingQuestion(_a) {
    var question = _a.question, forceDisableHtml = _a.forceDisableHtml, displayQuestionIndex = _a.displayQuestionIndex, appearance = _a.appearance, onSubmit = _a.onSubmit, onPreviewSubmit = _a.onPreviewSubmit, initialValue = _a.initialValue;
    var scale = question.scale;
    var starting = question.scale === 10 ? 0 : 1;
    var _b = __read((0, hooks_1.useState)(function () {
        if ((0, core_1.isNumber)(initialValue)) {
            return initialValue;
        }
        if ((0, core_1.isArray)(initialValue) && initialValue.length > 0 && (0, core_1.isNumber)(parseInt(initialValue[0]))) {
            return parseInt(initialValue[0]);
        }
        if ((0, core_1.isString)(initialValue) && (0, core_1.isNumber)(parseInt(initialValue))) {
            return parseInt(initialValue);
        }
        return null;
    }), 2), rating = _b[0], setRating = _b[1];
    var isPreviewMode = (0, surveys_extension_utils_1.useSurveyContext)().isPreviewMode;
    var handleSubmit = function (num) {
        if (isPreviewMode) {
            return onPreviewSubmit(num);
        }
        return onSubmit(num);
    };
    return (<preact_1.Fragment>
            <div className="question-container">
                <QuestionHeader_1.QuestionHeader question={question} forceDisableHtml={forceDisableHtml}/>
                <div className="rating-section">
                    <div className="rating-options">
                        {question.display === 'emoji' && (<div className="rating-options-emoji">
                                {(question.scale === 3 ? threeScaleEmojis : fiveScaleEmojis).map(function (emoji, idx) {
                var active = idx + 1 === rating;
                return (<button aria-label={"Rate ".concat(idx + 1)} className={"ratings-emoji question-".concat(displayQuestionIndex, "-rating-").concat(idx, " ").concat(active ? 'rating-active' : '')} value={idx + 1} key={idx} type="button" onClick={function () {
                        var response = idx + 1;
                        setRating(response);
                        if (question.skipSubmitButton) {
                            handleSubmit(response);
                        }
                    }}>
                                            {emoji}
                                        </button>);
            })}
                            </div>)}
                        {question.display === 'number' && (<div className="rating-options-number" style={{ gridTemplateColumns: "repeat(".concat(scale - starting + 1, ", minmax(0, 1fr))") }}>
                                {getScaleNumbers(question.scale).map(function (number, idx) {
                var active = rating === number;
                return (<RatingButton key={idx} displayQuestionIndex={displayQuestionIndex} active={active} appearance={appearance} num={number} setActiveNumber={function (response) {
                        setRating(response);
                        if (question.skipSubmitButton) {
                            handleSubmit(response);
                        }
                    }}/>);
            })}
                            </div>)}
                    </div>
                    <div className="rating-text">
                        <div>{question.lowerBoundLabel}</div>
                        <div>{question.upperBoundLabel}</div>
                    </div>
                </div>
            </div>
            <BottomSection_1.BottomSection text={question.buttonText || (appearance === null || appearance === void 0 ? void 0 : appearance.submitButtonText) || 'Submit'} submitDisabled={(0, core_1.isNull)(rating) && !question.optional} appearance={appearance} onSubmit={function () { return onSubmit(rating); }} onPreviewSubmit={function () { return onPreviewSubmit(rating); }} skipSubmitButton={question.skipSubmitButton}/>
        </preact_1.Fragment>);
}
function RatingButton(_a) {
    var num = _a.num, active = _a.active, displayQuestionIndex = _a.displayQuestionIndex, setActiveNumber = _a.setActiveNumber;
    return (<button aria-label={"Rate ".concat(num)} className={"ratings-number question-".concat(displayQuestionIndex, "-rating-").concat(num, " ").concat(active ? 'rating-active' : '')} type="button" onClick={function () {
            setActiveNumber(num);
        }}>
            {num}
        </button>);
}
function MultipleChoiceQuestion(_a) {
    var question = _a.question, forceDisableHtml = _a.forceDisableHtml, displayQuestionIndex = _a.displayQuestionIndex, appearance = _a.appearance, onSubmit = _a.onSubmit, onPreviewSubmit = _a.onPreviewSubmit, initialValue = _a.initialValue;
    var openChoiceInputRef = (0, hooks_1.useRef)(null);
    var choices = (0, hooks_1.useMemo)(function () { return (0, surveys_extension_utils_1.getDisplayOrderChoices)(question); }, [question]);
    var _b = __read((0, hooks_1.useState)(function () {
        return initializeSelectedChoices(initialValue, question.type);
    }), 2), selectedChoices = _b[0], setSelectedChoices = _b[1];
    var _c = __read((0, hooks_1.useState)(function () {
        return initializeOpenEndedState(initialValue, choices);
    }), 2), openEndedState = _c[0], setOpenEndedState = _c[1];
    var isPreviewMode = (0, surveys_extension_utils_1.useSurveyContext)().isPreviewMode;
    var isSingleChoiceQuestion = question.type === posthog_surveys_types_1.SurveyQuestionType.SingleChoice;
    var isMultipleChoiceQuestion = question.type === posthog_surveys_types_1.SurveyQuestionType.MultipleChoice;
    var shouldSkipSubmit = question.skipSubmitButton && isSingleChoiceQuestion && !question.hasOpenChoice;
    var handleChoiceChange = function (val, isOpenChoice) {
        if (isOpenChoice) {
            var newOpenSelected_1 = !openEndedState.isSelected;
            setOpenEndedState(function (prev) { return (__assign(__assign({}, prev), { isSelected: newOpenSelected_1, inputValue: newOpenSelected_1 ? prev.inputValue : '' })); });
            if (isSingleChoiceQuestion) {
                setSelectedChoices('');
            }
            // Focus the input when open choice is selected, slight delay because of the animation
            if (newOpenSelected_1) {
                setTimeout(function () { var _a; return (_a = openChoiceInputRef.current) === null || _a === void 0 ? void 0 : _a.focus(); }, 75);
            }
            return;
        }
        if (isSingleChoiceQuestion) {
            setSelectedChoices(val);
            // Deselect open choice when selecting another option
            setOpenEndedState(function (prev) { return (__assign(__assign({}, prev), { isSelected: false, inputValue: '' })); });
            if (shouldSkipSubmit) {
                onSubmit(val);
                if (isPreviewMode) {
                    onPreviewSubmit(val);
                }
            }
            return;
        }
        if (isMultipleChoiceQuestion && (0, core_1.isArray)(selectedChoices)) {
            if (selectedChoices.includes(val)) {
                setSelectedChoices(selectedChoices.filter(function (choice) { return choice !== val; }));
            }
            else {
                setSelectedChoices(__spreadArray(__spreadArray([], __read(selectedChoices), false), [val], false));
            }
        }
    };
    var handleOpenEndedInputChange = function (e) {
        e.stopPropagation();
        var newValue = e.currentTarget.value;
        setOpenEndedState(function (prev) { return (__assign(__assign({}, prev), { inputValue: newValue })); });
        if (isSingleChoiceQuestion) {
            setSelectedChoices(newValue);
        }
    };
    var handleOpenEndedKeyDown = function (e) {
        e.stopPropagation();
        // Handle Enter key to submit form if valid
        if (e.key === 'Enter' && !isSubmitDisabled()) {
            e.preventDefault();
            handleSubmit();
        }
        // Handle Escape key to clear input and deselect
        if (e.key === 'Escape') {
            e.preventDefault();
            setOpenEndedState(function (prev) { return (__assign(__assign({}, prev), { isSelected: false, inputValue: '' })); });
            if (isSingleChoiceQuestion) {
                setSelectedChoices(null);
            }
        }
    };
    var isSubmitDisabled = function () {
        if (question.optional) {
            return false;
        }
        if ((0, core_1.isNull)(selectedChoices)) {
            return true;
        }
        if ((0, core_1.isArray)(selectedChoices)) {
            if (!openEndedState.isSelected && selectedChoices.length === 0) {
                return true;
            }
        }
        if (openEndedState.isSelected && openEndedState.inputValue.trim() === '') {
            return true;
        }
        return false;
    };
    var handleSubmit = function () {
        if (openEndedState.isSelected && isMultipleChoiceQuestion) {
            if ((0, core_1.isArray)(selectedChoices)) {
                isPreviewMode
                    ? onPreviewSubmit(__spreadArray(__spreadArray([], __read(selectedChoices), false), [openEndedState.inputValue], false))
                    : onSubmit(__spreadArray(__spreadArray([], __read(selectedChoices), false), [openEndedState.inputValue], false));
            }
        }
        else {
            isPreviewMode ? onPreviewSubmit(selectedChoices) : onSubmit(selectedChoices);
        }
    };
    return (<preact_1.Fragment>
            <div className="question-container">
                <QuestionHeader_1.QuestionHeader question={question} forceDisableHtml={forceDisableHtml}/>
                <fieldset className="multiple-choice-options limit-height">
                    <legend className="sr-only">
                        {isMultipleChoiceQuestion ? ' Select all that apply' : ' Select one'}
                    </legend>
                    {choices.map(function (choice, idx) {
            var isOpenChoice = !!question.hasOpenChoice && idx === question.choices.length - 1;
            var inputId = "surveyQuestion".concat(displayQuestionIndex, "Choice").concat(idx);
            var openInputId = "".concat(inputId, "Open");
            var isChecked = isOpenChoice
                ? openEndedState.isSelected
                : isSingleChoiceQuestion
                    ? selectedChoices === choice
                    : (0, core_1.isArray)(selectedChoices) && selectedChoices.includes(choice);
            return (<label className={isOpenChoice ? 'choice-option-open' : ''} key={idx}>
                                <div className="response-choice">
                                    <input type={isSingleChoiceQuestion ? 'radio' : 'checkbox'} name={inputId} checked={isChecked} onChange={function () { return handleChoiceChange(choice, isOpenChoice); }} id={inputId} aria-controls={openInputId}/>
                                    <span>{isOpenChoice ? "".concat(choice, ":") : choice}</span>
                                </div>
                                {isOpenChoice && (<input type="text" ref={openChoiceInputRef} id={openInputId} name={"question".concat(displayQuestionIndex, "Open")} value={openEndedState.inputValue} onKeyDown={handleOpenEndedKeyDown} onInput={handleOpenEndedInputChange} onClick={function (e) {
                        // Ensure the checkbox/radio gets checked when clicking the input
                        if (!openEndedState.isSelected) {
                            handleChoiceChange(choice, true);
                        }
                        e.stopPropagation();
                    }} aria-label={"".concat(choice, " - please specify")}/>)}
                            </label>);
        })}
                </fieldset>
            </div>
            <BottomSection_1.BottomSection text={question.buttonText || 'Submit'} submitDisabled={isSubmitDisabled()} appearance={appearance} onSubmit={handleSubmit} onPreviewSubmit={handleSubmit} skipSubmitButton={shouldSkipSubmit}/>
        </preact_1.Fragment>);
}
var threeScaleEmojis = [icons_1.dissatisfiedEmoji, icons_1.neutralEmoji, icons_1.satisfiedEmoji];
var fiveScaleEmojis = [icons_1.veryDissatisfiedEmoji, icons_1.dissatisfiedEmoji, icons_1.neutralEmoji, icons_1.satisfiedEmoji, icons_1.verySatisfiedEmoji];
var fiveScaleNumbers = [1, 2, 3, 4, 5];
var sevenScaleNumbers = [1, 2, 3, 4, 5, 6, 7];
var tenScaleNumbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
function getScaleNumbers(scale) {
    switch (scale) {
        case 5:
            return fiveScaleNumbers;
        case 7:
            return sevenScaleNumbers;
        case 10:
            return tenScaleNumbers;
        default:
            return fiveScaleNumbers;
    }
}
//# sourceMappingURL=QuestionTypes.jsx.map