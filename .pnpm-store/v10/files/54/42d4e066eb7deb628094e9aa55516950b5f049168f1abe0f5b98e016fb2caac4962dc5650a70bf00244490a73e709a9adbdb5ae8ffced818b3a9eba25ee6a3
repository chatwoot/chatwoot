"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.QuestionHeader = QuestionHeader;
exports.Cancel = Cancel;
var preact_1 = require("preact");
var hooks_1 = require("preact/hooks");
var posthog_surveys_types_1 = require("../../../posthog-surveys-types");
var icons_1 = require("../icons");
var surveys_extension_utils_1 = require("../surveys-extension-utils");
function QuestionHeader(_a) {
    var question = _a.question, forceDisableHtml = _a.forceDisableHtml, htmlFor = _a.htmlFor;
    var TitleComponent = question.type === posthog_surveys_types_1.SurveyQuestionType.Open ? 'label' : 'h3';
    return (<div class="question-header">
            <TitleComponent className="survey-question" htmlFor={htmlFor}>
                {question.question}
            </TitleComponent>
            {question.description &&
            (0, surveys_extension_utils_1.renderChildrenAsTextOrHtml)({
                component: (0, preact_1.h)('p', { className: 'survey-question-description' }),
                children: question.description,
                renderAsHtml: !forceDisableHtml && question.descriptionContentType !== 'text',
            })}
        </div>);
}
function Cancel(_a) {
    var onClick = _a.onClick;
    var isPreviewMode = (0, hooks_1.useContext)(surveys_extension_utils_1.SurveyContext).isPreviewMode;
    return (<button className="form-cancel" onClick={onClick} disabled={isPreviewMode} aria-label="Close survey" type="button">
            {icons_1.cancelSVG}
        </button>);
}
//# sourceMappingURL=QuestionHeader.jsx.map