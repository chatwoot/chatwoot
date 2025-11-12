"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Autocapture = void 0;
exports.getAugmentPropertiesFromElement = getAugmentPropertiesFromElement;
exports.previousElementSibling = previousElementSibling;
exports.getDefaultProperties = getDefaultProperties;
exports.getPropertiesFromElement = getPropertiesFromElement;
exports.autocapturePropertiesForElement = autocapturePropertiesForElement;
var utils_1 = require("./utils");
var autocapture_utils_1 = require("./autocapture-utils");
var rageclick_1 = __importDefault(require("./extensions/rageclick"));
var types_1 = require("./types");
var constants_1 = require("./constants");
var core_1 = require("@posthog/core");
var logger_1 = require("./utils/logger");
var globals_1 = require("./utils/globals");
var request_utils_1 = require("./utils/request-utils");
var element_utils_1 = require("./utils/element-utils");
var core_2 = require("@posthog/core");
var logger = (0, logger_1.createLogger)('[AutoCapture]');
function limitText(length, text) {
    if (text.length > length) {
        return text.slice(0, length) + '...';
    }
    return text;
}
function getAugmentPropertiesFromElement(elem) {
    var shouldCaptureEl = (0, autocapture_utils_1.shouldCaptureElement)(elem);
    if (!shouldCaptureEl) {
        return {};
    }
    var props = {};
    (0, utils_1.each)(elem.attributes, function (attr) {
        if (attr.name && attr.name.indexOf('data-ph-capture-attribute') === 0) {
            var propertyKey = attr.name.replace('data-ph-capture-attribute-', '');
            var propertyValue = attr.value;
            if (propertyKey && propertyValue && (0, autocapture_utils_1.shouldCaptureValue)(propertyValue)) {
                props[propertyKey] = propertyValue;
            }
        }
    });
    return props;
}
function previousElementSibling(el) {
    if (el.previousElementSibling) {
        return el.previousElementSibling;
    }
    var _el = el;
    do {
        _el = _el.previousSibling; // resolves to ChildNode->Node, which is Element's parent class
    } while (_el && !(0, element_utils_1.isElementNode)(_el));
    return _el;
}
function getDefaultProperties(eventType) {
    return {
        $event_type: eventType,
        $ce_version: 1,
    };
}
function getPropertiesFromElement(elem, maskAllAttributes, maskText, elementAttributeIgnorelist) {
    var tag_name = elem.tagName.toLowerCase();
    var props = {
        tag_name: tag_name,
    };
    if (autocapture_utils_1.autocaptureCompatibleElements.indexOf(tag_name) > -1 && !maskText) {
        if (tag_name.toLowerCase() === 'a' || tag_name.toLowerCase() === 'button') {
            props['$el_text'] = limitText(1024, (0, autocapture_utils_1.getDirectAndNestedSpanText)(elem));
        }
        else {
            props['$el_text'] = limitText(1024, (0, autocapture_utils_1.getSafeText)(elem));
        }
    }
    var classes = (0, autocapture_utils_1.getClassNames)(elem);
    if (classes.length > 0)
        props['classes'] = classes.filter(function (c) {
            return c !== '';
        });
    // capture the deny list here because this not-a-class class makes it tricky to use this.config in the function below
    (0, utils_1.each)(elem.attributes, function (attr) {
        // Only capture attributes we know are safe
        if ((0, autocapture_utils_1.isSensitiveElement)(elem) && ['name', 'id', 'class', 'aria-label'].indexOf(attr.name) === -1)
            return;
        if (elementAttributeIgnorelist === null || elementAttributeIgnorelist === void 0 ? void 0 : elementAttributeIgnorelist.includes(attr.name))
            return;
        if (!maskAllAttributes && (0, autocapture_utils_1.shouldCaptureValue)(attr.value) && !(0, autocapture_utils_1.isAngularStyleAttr)(attr.name)) {
            var value = attr.value;
            if (attr.name === 'class') {
                // html attributes can _technically_ contain linebreaks,
                // but we're very intolerant of them in the class string,
                // so we strip them.
                value = (0, autocapture_utils_1.splitClassString)(value).join(' ');
            }
            props['attr__' + attr.name] = limitText(1024, value);
        }
    });
    var nthChild = 1;
    var nthOfType = 1;
    var currentElem = elem;
    while ((currentElem = previousElementSibling(currentElem))) {
        // eslint-disable-line no-cond-assign
        nthChild++;
        if (currentElem.tagName === elem.tagName) {
            nthOfType++;
        }
    }
    props['nth_child'] = nthChild;
    props['nth_of_type'] = nthOfType;
    return props;
}
function autocapturePropertiesForElement(target, _a) {
    var _b, _c, _d, _e;
    var e = _a.e, maskAllElementAttributes = _a.maskAllElementAttributes, maskAllText = _a.maskAllText, elementAttributeIgnoreList = _a.elementAttributeIgnoreList, elementsChainAsString = _a.elementsChainAsString;
    var targetElementList = [target];
    var curEl = target;
    while (curEl.parentNode && !(0, element_utils_1.isTag)(curEl, 'body')) {
        if ((0, element_utils_1.isDocumentFragment)(curEl.parentNode)) {
            targetElementList.push(curEl.parentNode.host);
            curEl = curEl.parentNode.host;
            continue;
        }
        targetElementList.push(curEl.parentNode);
        curEl = curEl.parentNode;
    }
    var elementsJson = [];
    var autocaptureAugmentProperties = {};
    var href = false;
    var explicitNoCapture = false;
    (0, utils_1.each)(targetElementList, function (el) {
        var shouldCaptureEl = (0, autocapture_utils_1.shouldCaptureElement)(el);
        // if the element or a parent element is an anchor tag
        // include the href as a property
        if (el.tagName.toLowerCase() === 'a') {
            href = el.getAttribute('href');
            href = shouldCaptureEl && href && (0, autocapture_utils_1.shouldCaptureValue)(href) && href;
        }
        // allow users to programmatically prevent capturing of elements by adding class 'ph-no-capture'
        var classes = (0, autocapture_utils_1.getClassNames)(el);
        if ((0, core_2.includes)(classes, 'ph-no-capture')) {
            explicitNoCapture = true;
        }
        elementsJson.push(getPropertiesFromElement(el, maskAllElementAttributes, maskAllText, elementAttributeIgnoreList));
        var augmentProperties = getAugmentPropertiesFromElement(el);
        (0, utils_1.extend)(autocaptureAugmentProperties, augmentProperties);
    });
    if (explicitNoCapture) {
        return { props: {}, explicitNoCapture: explicitNoCapture };
    }
    if (!maskAllText) {
        // if the element is a button or anchor tag get the span text from any
        // children and include it as/with the text property on the parent element
        if (target.tagName.toLowerCase() === 'a' || target.tagName.toLowerCase() === 'button') {
            elementsJson[0]['$el_text'] = (0, autocapture_utils_1.getDirectAndNestedSpanText)(target);
        }
        else {
            elementsJson[0]['$el_text'] = (0, autocapture_utils_1.getSafeText)(target);
        }
    }
    var externalHref;
    if (href) {
        elementsJson[0]['attr__href'] = href;
        var hrefHost = (_b = (0, request_utils_1.convertToURL)(href)) === null || _b === void 0 ? void 0 : _b.host;
        var locationHost = (_c = globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.location) === null || _c === void 0 ? void 0 : _c.host;
        if (hrefHost && locationHost && hrefHost !== locationHost) {
            externalHref = href;
        }
    }
    var props = (0, utils_1.extend)(getDefaultProperties(e.type), 
    // Sending "$elements" is deprecated. Only one client on US cloud uses this.
    !elementsChainAsString ? { $elements: elementsJson } : {}, 
    // Always send $elements_chain, as it's needed downstream in site app filtering
    { $elements_chain: (0, autocapture_utils_1.getElementsChainString)(elementsJson) }, ((_d = elementsJson[0]) === null || _d === void 0 ? void 0 : _d['$el_text']) ? { $el_text: (_e = elementsJson[0]) === null || _e === void 0 ? void 0 : _e['$el_text'] } : {}, externalHref && e.type === 'click' ? { $external_click_url: externalHref } : {}, autocaptureAugmentProperties);
    return { props: props };
}
var Autocapture = /** @class */ (function () {
    function Autocapture(instance) {
        this._initialized = false;
        this._isDisabledServerSide = null;
        this.rageclicks = new rageclick_1.default();
        this._elementsChainAsString = false;
        this.instance = instance;
        this._elementSelectors = null;
    }
    Object.defineProperty(Autocapture.prototype, "_config", {
        get: function () {
            var _a, _b;
            var config = (0, core_1.isObject)(this.instance.config.autocapture) ? this.instance.config.autocapture : {};
            // precompile the regex
            config.url_allowlist = (_a = config.url_allowlist) === null || _a === void 0 ? void 0 : _a.map(function (url) { return new RegExp(url); });
            config.url_ignorelist = (_b = config.url_ignorelist) === null || _b === void 0 ? void 0 : _b.map(function (url) { return new RegExp(url); });
            return config;
        },
        enumerable: false,
        configurable: true
    });
    Autocapture.prototype._addDomEventHandlers = function () {
        var _this = this;
        if (!this.isBrowserSupported()) {
            logger.info('Disabling Automatic Event Collection because this browser is not supported');
            return;
        }
        if (!globals_1.window || !globals_1.document) {
            return;
        }
        var handler = function (e) {
            e = e || (globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.event);
            try {
                _this._captureEvent(e);
            }
            catch (error) {
                logger.error('Failed to capture event', error);
            }
        };
        (0, utils_1.addEventListener)(globals_1.document, 'submit', handler, { capture: true });
        (0, utils_1.addEventListener)(globals_1.document, 'change', handler, { capture: true });
        (0, utils_1.addEventListener)(globals_1.document, 'click', handler, { capture: true });
        if (this._config.capture_copied_text) {
            var copiedTextHandler = function (e) {
                e = e || (globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.event);
                _this._captureEvent(e, types_1.COPY_AUTOCAPTURE_EVENT);
            };
            (0, utils_1.addEventListener)(globals_1.document, 'copy', copiedTextHandler, { capture: true });
            (0, utils_1.addEventListener)(globals_1.document, 'cut', copiedTextHandler, { capture: true });
        }
    };
    Autocapture.prototype.startIfEnabled = function () {
        if (this.isEnabled && !this._initialized) {
            this._addDomEventHandlers();
            this._initialized = true;
        }
    };
    Autocapture.prototype.onRemoteConfig = function (response) {
        var _a;
        if (response.elementsChainAsString) {
            this._elementsChainAsString = response.elementsChainAsString;
        }
        if (this.instance.persistence) {
            this.instance.persistence.register((_a = {},
                _a[constants_1.AUTOCAPTURE_DISABLED_SERVER_SIDE] = !!response['autocapture_opt_out'],
                _a));
        }
        // store this in-memory in case persistence is disabled
        this._isDisabledServerSide = !!response['autocapture_opt_out'];
        this.startIfEnabled();
    };
    Autocapture.prototype.setElementSelectors = function (selectors) {
        this._elementSelectors = selectors;
    };
    Autocapture.prototype.getElementSelectors = function (element) {
        var _a;
        var elementSelectors = [];
        (_a = this._elementSelectors) === null || _a === void 0 ? void 0 : _a.forEach(function (selector) {
            var matchedElements = globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.querySelectorAll(selector);
            matchedElements === null || matchedElements === void 0 ? void 0 : matchedElements.forEach(function (matchedElement) {
                if (element === matchedElement) {
                    elementSelectors.push(selector);
                }
            });
        });
        return elementSelectors;
    };
    Object.defineProperty(Autocapture.prototype, "isEnabled", {
        get: function () {
            var _a, _b;
            var persistedServerDisabled = (_a = this.instance.persistence) === null || _a === void 0 ? void 0 : _a.props[constants_1.AUTOCAPTURE_DISABLED_SERVER_SIDE];
            var memoryDisabled = this._isDisabledServerSide;
            if ((0, core_1.isNull)(memoryDisabled) && !(0, core_1.isBoolean)(persistedServerDisabled) && !this.instance._shouldDisableFlags()) {
                // We only enable if we know that the server has not disabled it (unless /flags is disabled)
                return false;
            }
            var disabledServer = (_b = this._isDisabledServerSide) !== null && _b !== void 0 ? _b : !!persistedServerDisabled;
            var disabledClient = !this.instance.config.autocapture;
            return !disabledClient && !disabledServer;
        },
        enumerable: false,
        configurable: true
    });
    Autocapture.prototype._captureEvent = function (e, eventName) {
        var _a, _b;
        if (eventName === void 0) { eventName = '$autocapture'; }
        if (!this.isEnabled) {
            return;
        }
        /*** Don't mess with this code without running IE8 tests on it ***/
        var target = (0, autocapture_utils_1.getEventTarget)(e);
        if ((0, element_utils_1.isTextNode)(target)) {
            // defeat Safari bug (see: http://www.quirksmode.org/js/events_properties.html)
            target = (target.parentNode || null);
        }
        if (eventName === '$autocapture' && e.type === 'click' && e instanceof MouseEvent) {
            if (this.instance.config.rageclick &&
                ((_a = this.rageclicks) === null || _a === void 0 ? void 0 : _a.isRageClick(e.clientX, e.clientY, new Date().getTime()))) {
                this._captureEvent(e, '$rageclick');
            }
        }
        var isCopyAutocapture = eventName === types_1.COPY_AUTOCAPTURE_EVENT;
        if (target &&
            (0, autocapture_utils_1.shouldCaptureDomEvent)(target, e, this._config, 
            // mostly this method cares about the target element, but in the case of copy events,
            // we want some of the work this check does without insisting on the target element's type
            isCopyAutocapture, 
            // we also don't want to restrict copy checks to clicks,
            // so we pass that knowledge in here, rather than add the logic inside the check
            isCopyAutocapture ? ['copy', 'cut'] : undefined)) {
            var _c = autocapturePropertiesForElement(target, {
                e: e,
                maskAllElementAttributes: this.instance.config.mask_all_element_attributes,
                maskAllText: this.instance.config.mask_all_text,
                elementAttributeIgnoreList: this._config.element_attribute_ignorelist,
                elementsChainAsString: this._elementsChainAsString,
            }), props = _c.props, explicitNoCapture = _c.explicitNoCapture;
            if (explicitNoCapture) {
                return false;
            }
            var elementSelectors = this.getElementSelectors(target);
            if (elementSelectors && elementSelectors.length > 0) {
                props['$element_selectors'] = elementSelectors;
            }
            if (eventName === types_1.COPY_AUTOCAPTURE_EVENT) {
                // you can't read the data from the clipboard event,
                // but you can guess that you can read it from the window's current selection
                var selectedContent = (0, autocapture_utils_1.makeSafeText)((_b = globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.getSelection()) === null || _b === void 0 ? void 0 : _b.toString());
                var clipType = e.type || 'clipboard';
                if (!selectedContent) {
                    return false;
                }
                props['$selected_content'] = selectedContent;
                props['$copy_type'] = clipType;
            }
            this.instance.capture(eventName, props);
            return true;
        }
    };
    Autocapture.prototype.isBrowserSupported = function () {
        return (0, core_1.isFunction)(globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.querySelectorAll);
    };
    return Autocapture;
}());
exports.Autocapture = Autocapture;
//# sourceMappingURL=autocapture.js.map