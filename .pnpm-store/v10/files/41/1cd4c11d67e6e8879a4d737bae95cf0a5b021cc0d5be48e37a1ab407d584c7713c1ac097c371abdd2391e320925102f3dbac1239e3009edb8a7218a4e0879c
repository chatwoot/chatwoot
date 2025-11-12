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
var __values = (this && this.__values) || function(o) {
    var s = typeof Symbol === "function" && Symbol.iterator, m = s && o[s], i = 0;
    if (m) return m.call(o);
    if (o && typeof o.length === "number") return {
        next: function () {
            if (o && i >= o.length) o = void 0;
            return { value: o && o[i++], done: !o };
        }
    };
    throw new TypeError(s ? "Object is not iterable." : "Symbol.iterator is not defined.");
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.autocaptureCompatibleElements = void 0;
exports.splitClassString = splitClassString;
exports.getClassNames = getClassNames;
exports.makeSafeText = makeSafeText;
exports.getSafeText = getSafeText;
exports.getEventTarget = getEventTarget;
exports.getParentElement = getParentElement;
exports.shouldCaptureDomEvent = shouldCaptureDomEvent;
exports.shouldCaptureElement = shouldCaptureElement;
exports.isSensitiveElement = isSensitiveElement;
exports.shouldCaptureValue = shouldCaptureValue;
exports.isAngularStyleAttr = isAngularStyleAttr;
exports.getDirectAndNestedSpanText = getDirectAndNestedSpanText;
exports.getNestedSpanText = getNestedSpanText;
exports.getElementsChainString = getElementsChainString;
var utils_1 = require("./utils");
var core_1 = require("@posthog/core");
var logger_1 = require("./utils/logger");
var globals_1 = require("./utils/globals");
var element_utils_1 = require("./utils/element-utils");
var core_2 = require("@posthog/core");
function splitClassString(s) {
    return s ? (0, core_2.trim)(s).split(/\s+/) : [];
}
function checkForURLMatches(urlsList) {
    var url = globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.location.href;
    return !!(url && urlsList && urlsList.some(function (regex) { return url.match(regex); }));
}
/*
 * Get the className of an element, accounting for edge cases where element.className is an object
 *
 * Because this is a string it can contain unexpected characters
 * So, this method safely splits the className and returns that array.
 */
function getClassNames(el) {
    var className = '';
    switch (typeof el.className) {
        case 'string':
            className = el.className;
            break;
        // TODO: when is this ever used?
        case 'object': // handle cases where className might be SVGAnimatedString or some other type
            className =
                (el.className && 'baseVal' in el.className ? el.className.baseVal : null) ||
                    el.getAttribute('class') ||
                    '';
            break;
        default:
            className = '';
    }
    return splitClassString(className);
}
function makeSafeText(s) {
    if ((0, core_1.isNullish)(s)) {
        return null;
    }
    return ((0, core_2.trim)(s)
        // scrub potentially sensitive values
        .split(/(\s+)/)
        .filter(function (s) { return shouldCaptureValue(s); })
        .join('')
        // normalize whitespace
        .replace(/[\r\n]/g, ' ')
        .replace(/[ ]+/g, ' ')
        // truncate
        .substring(0, 255));
}
/*
 * Get the direct text content of an element, protecting against sensitive data collection.
 * Concats textContent of each of the element's text node children; this avoids potential
 * collection of sensitive data that could happen if we used element.textContent and the
 * element had sensitive child elements, since element.textContent includes child content.
 * Scrubs values that look like they could be sensitive (i.e. cc or ssn number).
 * @param {Element} el - element to get the text of
 * @returns {string} the element's direct text content
 */
function getSafeText(el) {
    var elText = '';
    if (shouldCaptureElement(el) && !isSensitiveElement(el) && el.childNodes && el.childNodes.length) {
        (0, utils_1.each)(el.childNodes, function (child) {
            var _a;
            if ((0, element_utils_1.isTextNode)(child) && child.textContent) {
                elText += (_a = makeSafeText(child.textContent)) !== null && _a !== void 0 ? _a : '';
            }
        });
    }
    return (0, core_2.trim)(elText);
}
function getEventTarget(e) {
    var _a;
    // https://developer.mozilla.org/en-US/docs/Web/API/Event/target#Compatibility_notes
    if ((0, core_1.isUndefined)(e.target)) {
        return e.srcElement || null;
    }
    else {
        if ((_a = e.target) === null || _a === void 0 ? void 0 : _a.shadowRoot) {
            return e.composedPath()[0] || null;
        }
        return e.target || null;
    }
}
exports.autocaptureCompatibleElements = ['a', 'button', 'form', 'input', 'select', 'textarea', 'label'];
/*
 if there is no config, then all elements are allowed
 if there is a config, and there is an allow list, then only elements in the allow list are allowed
 assumes that some other code is checking this element's parents
 */
function checkIfElementTreePassesElementAllowList(elements, autocaptureConfig) {
    var e_1, _a;
    var allowlist = autocaptureConfig === null || autocaptureConfig === void 0 ? void 0 : autocaptureConfig.element_allowlist;
    if ((0, core_1.isUndefined)(allowlist)) {
        // everything is allowed, when there is no allow list
        return true;
    }
    var _loop_1 = function (el) {
        if (allowlist.some(function (elementType) { return el.tagName.toLowerCase() === elementType; })) {
            return { value: true };
        }
    };
    try {
        // check each element in the tree
        // if any of the elements are in the allow list, then the tree is allowed
        for (var elements_1 = __values(elements), elements_1_1 = elements_1.next(); !elements_1_1.done; elements_1_1 = elements_1.next()) {
            var el = elements_1_1.value;
            var state_1 = _loop_1(el);
            if (typeof state_1 === "object")
                return state_1.value;
        }
    }
    catch (e_1_1) { e_1 = { error: e_1_1 }; }
    finally {
        try {
            if (elements_1_1 && !elements_1_1.done && (_a = elements_1.return)) _a.call(elements_1);
        }
        finally { if (e_1) throw e_1.error; }
    }
    // otherwise there is an allow list and this element tree didn't match it
    return false;
}
/*
 if there is no config, then all elements are allowed
 if there is a config, and there is an allow list, then
 only elements that match the css selector in the allow list are allowed
 assumes that some other code is checking this element's parents
 */
function checkIfElementTreePassesCSSSelectorAllowList(elements, autocaptureConfig) {
    var e_2, _a;
    var allowlist = autocaptureConfig === null || autocaptureConfig === void 0 ? void 0 : autocaptureConfig.css_selector_allowlist;
    if ((0, core_1.isUndefined)(allowlist)) {
        // everything is allowed, when there is no allow list
        return true;
    }
    var _loop_2 = function (el) {
        if (allowlist.some(function (selector) { return el.matches(selector); })) {
            return { value: true };
        }
    };
    try {
        // check each element in the tree
        // if any of the elements are in the allow list, then the tree is allowed
        for (var elements_2 = __values(elements), elements_2_1 = elements_2.next(); !elements_2_1.done; elements_2_1 = elements_2.next()) {
            var el = elements_2_1.value;
            var state_2 = _loop_2(el);
            if (typeof state_2 === "object")
                return state_2.value;
        }
    }
    catch (e_2_1) { e_2 = { error: e_2_1 }; }
    finally {
        try {
            if (elements_2_1 && !elements_2_1.done && (_a = elements_2.return)) _a.call(elements_2);
        }
        finally { if (e_2) throw e_2.error; }
    }
    // otherwise there is an allow list and this element tree didn't match it
    return false;
}
function getParentElement(curEl) {
    var parentNode = curEl.parentNode;
    if (!parentNode || !(0, element_utils_1.isElementNode)(parentNode))
        return false;
    return parentNode;
}
/*
 * Check whether a DOM event should be "captured" or if it may contain sentitive data
 * using a variety of heuristics.
 * @param {Element} el - element to check
 * @param {Event} event - event to check
 * @param {Object} autocaptureConfig - autocapture config
 * @param {boolean} captureOnAnyElement - whether to capture on any element, clipboard autocapture doesn't restrict to "clickable" elements
 * @param {string[]} allowedEventTypes - event types to capture, normally just 'click', but some autocapture types react to different events, some elements have fixed events (e.g., form has "submit")
 * @returns {boolean} whether the event should be captured
 */
function shouldCaptureDomEvent(el, event, autocaptureConfig, captureOnAnyElement, allowedEventTypes) {
    if (autocaptureConfig === void 0) { autocaptureConfig = undefined; }
    if (!globals_1.window || !el || (0, element_utils_1.isTag)(el, 'html') || !(0, element_utils_1.isElementNode)(el)) {
        return false;
    }
    if (autocaptureConfig === null || autocaptureConfig === void 0 ? void 0 : autocaptureConfig.url_allowlist) {
        // if the current URL is not in the allow list, don't capture
        if (!checkForURLMatches(autocaptureConfig.url_allowlist)) {
            return false;
        }
    }
    if (autocaptureConfig === null || autocaptureConfig === void 0 ? void 0 : autocaptureConfig.url_ignorelist) {
        // if the current URL is in the ignore list, don't capture
        if (checkForURLMatches(autocaptureConfig.url_ignorelist)) {
            return false;
        }
    }
    if (autocaptureConfig === null || autocaptureConfig === void 0 ? void 0 : autocaptureConfig.dom_event_allowlist) {
        var allowlist = autocaptureConfig.dom_event_allowlist;
        if (allowlist && !allowlist.some(function (eventType) { return event.type === eventType; })) {
            return false;
        }
    }
    var parentIsUsefulElement = false;
    var targetElementList = [el];
    var parentNode = true;
    var curEl = el;
    while (curEl.parentNode && !(0, element_utils_1.isTag)(curEl, 'body')) {
        // If element is a shadow root, we skip it
        if ((0, element_utils_1.isDocumentFragment)(curEl.parentNode)) {
            targetElementList.push(curEl.parentNode.host);
            curEl = curEl.parentNode.host;
            continue;
        }
        parentNode = getParentElement(curEl);
        if (!parentNode)
            break;
        if (captureOnAnyElement || exports.autocaptureCompatibleElements.indexOf(parentNode.tagName.toLowerCase()) > -1) {
            parentIsUsefulElement = true;
        }
        else {
            var compStyles_1 = globals_1.window.getComputedStyle(parentNode);
            if (compStyles_1 && compStyles_1.getPropertyValue('cursor') === 'pointer') {
                parentIsUsefulElement = true;
            }
        }
        targetElementList.push(parentNode);
        curEl = parentNode;
    }
    if (!checkIfElementTreePassesElementAllowList(targetElementList, autocaptureConfig)) {
        return false;
    }
    if (!checkIfElementTreePassesCSSSelectorAllowList(targetElementList, autocaptureConfig)) {
        return false;
    }
    var compStyles = globals_1.window.getComputedStyle(el);
    if (compStyles && compStyles.getPropertyValue('cursor') === 'pointer' && event.type === 'click') {
        return true;
    }
    var tag = el.tagName.toLowerCase();
    switch (tag) {
        case 'html':
            return false;
        case 'form':
            return (allowedEventTypes || ['submit']).indexOf(event.type) >= 0;
        case 'input':
        case 'select':
        case 'textarea':
            return (allowedEventTypes || ['change', 'click']).indexOf(event.type) >= 0;
        default:
            if (parentIsUsefulElement)
                return (allowedEventTypes || ['click']).indexOf(event.type) >= 0;
            return ((allowedEventTypes || ['click']).indexOf(event.type) >= 0 &&
                (exports.autocaptureCompatibleElements.indexOf(tag) > -1 || el.getAttribute('contenteditable') === 'true'));
    }
}
/*
 * Check whether a DOM element should be "captured" or if it may contain sentitive data
 * using a variety of heuristics.
 * @param {Element} el - element to check
 * @returns {boolean} whether the element should be captured
 */
function shouldCaptureElement(el) {
    for (var curEl = el; curEl.parentNode && !(0, element_utils_1.isTag)(curEl, 'body'); curEl = curEl.parentNode) {
        var classes = getClassNames(curEl);
        if ((0, core_2.includes)(classes, 'ph-sensitive') || (0, core_2.includes)(classes, 'ph-no-capture')) {
            return false;
        }
    }
    if ((0, core_2.includes)(getClassNames(el), 'ph-include')) {
        return true;
    }
    // don't include hidden or password fields
    var type = el.type || '';
    if ((0, core_1.isString)(type)) {
        // it's possible for el.type to be a DOM element if el is a form with a child input[name="type"]
        switch (type.toLowerCase()) {
            case 'hidden':
                return false;
            case 'password':
                return false;
        }
    }
    // filter out data from fields that look like sensitive fields
    var name = el.name || el.id || '';
    // See https://github.com/posthog/posthog-js/issues/165
    // Under specific circumstances a bug caused .replace to be called on a DOM element
    // instead of a string, removing the element from the page. Ensure this issue is mitigated.
    if ((0, core_1.isString)(name)) {
        // it's possible for el.name or el.id to be a DOM element if el is a form with a child input[name="name"]
        var sensitiveNameRegex = /^cc|cardnum|ccnum|creditcard|csc|cvc|cvv|exp|pass|pwd|routing|seccode|securitycode|securitynum|socialsec|socsec|ssn/i;
        if (sensitiveNameRegex.test(name.replace(/[^a-zA-Z0-9]/g, ''))) {
            return false;
        }
    }
    return true;
}
/*
 * Check whether a DOM element is 'sensitive' and we should only capture limited data
 * @param {Element} el - element to check
 * @returns {boolean} whether the element should be captured
 */
function isSensitiveElement(el) {
    // don't send data from inputs or similar elements since there will always be
    // a risk of clientside javascript placing sensitive data in attributes
    var allowedInputTypes = ['button', 'checkbox', 'submit', 'reset'];
    if (((0, element_utils_1.isTag)(el, 'input') && !allowedInputTypes.includes(el.type)) ||
        (0, element_utils_1.isTag)(el, 'select') ||
        (0, element_utils_1.isTag)(el, 'textarea') ||
        el.getAttribute('contenteditable') === 'true') {
        return true;
    }
    return false;
}
// Define the core pattern for matching credit card numbers
var coreCCPattern = "(4[0-9]{12}(?:[0-9]{3})?)|(5[1-5][0-9]{14})|(6(?:011|5[0-9]{2})[0-9]{12})|(3[47][0-9]{13})|(3(?:0[0-5]|[68][0-9])[0-9]{11})|((?:2131|1800|35[0-9]{3})[0-9]{11})";
// Create the Anchored version of the regex by adding '^' at the start and '$' at the end
var anchoredCCRegex = new RegExp("^(?:".concat(coreCCPattern, ")$"));
// The Unanchored version is essentially the core pattern, usable as is for partial matches
var unanchoredCCRegex = new RegExp(coreCCPattern);
// Define the core pattern for matching SSNs with optional dashes
var coreSSNPattern = "\\d{3}-?\\d{2}-?\\d{4}";
// Create the Anchored version of the regex by adding '^' at the start and '$' at the end
var anchoredSSNRegex = new RegExp("^(".concat(coreSSNPattern, ")$"));
// The Unanchored version is essentially the core pattern itself, usable for partial matches
var unanchoredSSNRegex = new RegExp("(".concat(coreSSNPattern, ")"));
/*
 * Check whether a string value should be "captured" or if it may contain sensitive data
 * using a variety of heuristics.
 * @param {string} value - string value to check
 * @param {boolean} anchorRegexes - whether to anchor the regexes to the start and end of the string
 * @returns {boolean} whether the element should be captured
 */
function shouldCaptureValue(value, anchorRegexes) {
    if (anchorRegexes === void 0) { anchorRegexes = true; }
    if ((0, core_1.isNullish)(value)) {
        return false;
    }
    if ((0, core_1.isString)(value)) {
        value = (0, core_2.trim)(value);
        // check to see if input value looks like a credit card number
        // see: https://www.safaribooksonline.com/library/view/regular-expressions-cookbook/9781449327453/ch04s20.html
        var ccRegex = anchorRegexes ? anchoredCCRegex : unanchoredCCRegex;
        if (ccRegex.test((value || '').replace(/[- ]/g, ''))) {
            return false;
        }
        // check to see if input value looks like a social security number
        var ssnRegex = anchorRegexes ? anchoredSSNRegex : unanchoredSSNRegex;
        if (ssnRegex.test(value)) {
            return false;
        }
    }
    return true;
}
/*
 * Check whether an attribute name is an Angular style attr (either _ngcontent or _nghost)
 * These update on each build and lead to noise in the element chain
 * More details on the attributes here: https://angular.io/guide/view-encapsulation
 * @param {string} attributeName - string value to check
 * @returns {boolean} whether the element is an angular tag
 */
function isAngularStyleAttr(attributeName) {
    if ((0, core_1.isString)(attributeName)) {
        return attributeName.substring(0, 10) === '_ngcontent' || attributeName.substring(0, 7) === '_nghost';
    }
    return false;
}
/*
 * Iterate through children of a target element looking for span tags
 * and return the text content of the span tags, separated by spaces,
 * along with the direct text content of the target element
 * @param {Element} target - element to check
 * @returns {string} text content of the target element and its child span tags
 */
function getDirectAndNestedSpanText(target) {
    var text = getSafeText(target);
    text = "".concat(text, " ").concat(getNestedSpanText(target)).trim();
    return shouldCaptureValue(text) ? text : '';
}
/*
 * Iterate through children of a target element looking for span tags
 * and return the text content of the span tags, separated by spaces
 * @param {Element} target - element to check
 * @returns {string} text content of span tags
 */
function getNestedSpanText(target) {
    var text = '';
    if (target && target.childNodes && target.childNodes.length) {
        (0, utils_1.each)(target.childNodes, function (child) {
            var _a;
            if (child && ((_a = child.tagName) === null || _a === void 0 ? void 0 : _a.toLowerCase()) === 'span') {
                try {
                    var spanText = getSafeText(child);
                    text = "".concat(text, " ").concat(spanText).trim();
                    if (child.childNodes && child.childNodes.length) {
                        text = "".concat(text, " ").concat(getNestedSpanText(child)).trim();
                    }
                }
                catch (e) {
                    logger_1.logger.error('[AutoCapture]', e);
                }
            }
        });
    }
    return text;
}
/*
Back in the day storing events in Postgres we use Elements for autocapture events.
Now we're using elements_chain. We used to do this parsing/processing during ingestion.
This code is just copied over from ingestion, but we should optimize it
to create elements_chain string directly.
*/
function getElementsChainString(elements) {
    return elementsToString(extractElements(elements));
}
function escapeQuotes(input) {
    return input.replace(/"|\\"/g, '\\"');
}
function elementsToString(elements) {
    var ret = elements.map(function (element) {
        var e_3, _a;
        var _b, _c;
        var el_string = '';
        if (element.tag_name) {
            el_string += element.tag_name;
        }
        if (element.attr_class) {
            element.attr_class.sort();
            try {
                for (var _d = __values(element.attr_class), _e = _d.next(); !_e.done; _e = _d.next()) {
                    var single_class = _e.value;
                    el_string += ".".concat(single_class.replace(/"/g, ''));
                }
            }
            catch (e_3_1) { e_3 = { error: e_3_1 }; }
            finally {
                try {
                    if (_e && !_e.done && (_a = _d.return)) _a.call(_d);
                }
                finally { if (e_3) throw e_3.error; }
            }
        }
        var attributes = __assign(__assign(__assign(__assign(__assign({}, (element.text ? { text: element.text } : {})), { 'nth-child': (_b = element.nth_child) !== null && _b !== void 0 ? _b : 0, 'nth-of-type': (_c = element.nth_of_type) !== null && _c !== void 0 ? _c : 0 }), (element.href ? { href: element.href } : {})), (element.attr_id ? { attr_id: element.attr_id } : {})), element.attributes);
        var sortedAttributes = {};
        (0, utils_1.entries)(attributes)
            .sort(function (_a, _b) {
            var _c = __read(_a, 1), a = _c[0];
            var _d = __read(_b, 1), b = _d[0];
            return a.localeCompare(b);
        })
            .forEach(function (_a) {
            var _b = __read(_a, 2), key = _b[0], value = _b[1];
            return (sortedAttributes[escapeQuotes(key.toString())] = escapeQuotes(value.toString()));
        });
        el_string += ':';
        el_string += (0, utils_1.entries)(sortedAttributes)
            .map(function (_a) {
            var _b = __read(_a, 2), key = _b[0], value = _b[1];
            return "".concat(key, "=\"").concat(value, "\"");
        })
            .join('');
        return el_string;
    });
    return ret.join(';');
}
function extractElements(elements) {
    return elements.map(function (el) {
        var _a, _b;
        var response = {
            text: (_a = el['$el_text']) === null || _a === void 0 ? void 0 : _a.slice(0, 400),
            tag_name: el['tag_name'],
            href: (_b = el['attr__href']) === null || _b === void 0 ? void 0 : _b.slice(0, 2048),
            attr_class: extractAttrClass(el),
            attr_id: el['attr__id'],
            nth_child: el['nth_child'],
            nth_of_type: el['nth_of_type'],
            attributes: {},
        };
        (0, utils_1.entries)(el)
            .filter(function (_a) {
            var _b = __read(_a, 1), key = _b[0];
            return key.indexOf('attr__') === 0;
        })
            .forEach(function (_a) {
            var _b = __read(_a, 2), key = _b[0], value = _b[1];
            return (response.attributes[key] = value);
        });
        return response;
    });
}
function extractAttrClass(el) {
    var attr_class = el['attr__class'];
    if (!attr_class) {
        return undefined;
    }
    else if ((0, core_1.isArray)(attr_class)) {
        return attr_class;
    }
    else {
        return splitClassString(attr_class);
    }
}
//# sourceMappingURL=autocapture-utils.js.map