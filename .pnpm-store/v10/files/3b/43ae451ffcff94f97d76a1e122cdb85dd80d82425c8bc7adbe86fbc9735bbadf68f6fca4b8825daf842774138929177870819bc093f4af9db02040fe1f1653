"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConfirmationMessage = ConfirmationMessage;
var preact_1 = require("preact");
var surveys_extension_utils_1 = require("../surveys-extension-utils");
var BottomSection_1 = require("./BottomSection");
var QuestionHeader_1 = require("./QuestionHeader");
var hooks_1 = require("preact/hooks");
var surveys_extension_utils_2 = require("../surveys-extension-utils");
var utils_1 = require("../../../utils");
var globals_1 = require("../../../utils/globals");
// We cast the types here which is dangerous but protected by the top level generateSurveys call
var window = globals_1.window;
function ConfirmationMessage(_a) {
    var header = _a.header, description = _a.description, contentType = _a.contentType, forceDisableHtml = _a.forceDisableHtml, appearance = _a.appearance, onClose = _a.onClose;
    var isPopup = (0, hooks_1.useContext)(surveys_extension_utils_2.SurveyContext).isPopup;
    (0, hooks_1.useEffect)(function () {
        var handleKeyDown = function (event) {
            if (event.key === 'Enter' || event.key === 'Escape') {
                event.preventDefault();
                onClose();
            }
        };
        (0, utils_1.addEventListener)(window, 'keydown', handleKeyDown);
        return function () {
            window.removeEventListener('keydown', handleKeyDown);
        };
    }, [onClose]);
    return (<div className="thank-you-message" role="status" tabIndex={0} aria-atomic="true">
            {isPopup && <QuestionHeader_1.Cancel onClick={function () { return onClose(); }}/>}
            <h3 className="thank-you-message-header">{header}</h3>
            {description &&
            (0, surveys_extension_utils_1.renderChildrenAsTextOrHtml)({
                component: (0, preact_1.h)('p', { className: 'thank-you-message-body' }),
                children: description,
                renderAsHtml: !forceDisableHtml && contentType !== 'text',
            })}
            {isPopup && (<BottomSection_1.BottomSection text={appearance.thankYouMessageCloseButtonText || 'Close'} submitDisabled={false} appearance={appearance} onSubmit={function () { return onClose(); }}/>)}
        </div>);
}
//# sourceMappingURL=ConfirmationMessage.jsx.map