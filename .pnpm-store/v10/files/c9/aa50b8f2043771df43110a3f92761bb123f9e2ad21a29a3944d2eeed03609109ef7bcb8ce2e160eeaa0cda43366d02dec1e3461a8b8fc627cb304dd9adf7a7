"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.WebExperiments = exports.webExperimentUrlValidationMap = void 0;
var globals_1 = require("./utils/globals");
var constants_1 = require("./constants");
var core_1 = require("@posthog/core");
var request_utils_1 = require("./utils/request-utils");
var regex_utils_1 = require("./utils/regex-utils");
var logger_1 = require("./utils/logger");
var blocked_uas_1 = require("./utils/blocked-uas");
var event_utils_1 = require("./utils/event-utils");
exports.webExperimentUrlValidationMap = {
    icontains: function (conditionsUrl, location) {
        return !!globals_1.window && location.href.toLowerCase().indexOf(conditionsUrl.toLowerCase()) > -1;
    },
    not_icontains: function (conditionsUrl, location) {
        return !!globals_1.window && location.href.toLowerCase().indexOf(conditionsUrl.toLowerCase()) === -1;
    },
    regex: function (conditionsUrl, location) { return !!globals_1.window && (0, regex_utils_1.isMatchingRegex)(location.href, conditionsUrl); },
    not_regex: function (conditionsUrl, location) { return !!globals_1.window && !(0, regex_utils_1.isMatchingRegex)(location.href, conditionsUrl); },
    exact: function (conditionsUrl, location) { return location.href === conditionsUrl; },
    is_not: function (conditionsUrl, location) { return location.href !== conditionsUrl; },
};
var WebExperiments = /** @class */ (function () {
    function WebExperiments(_instance) {
        var _this = this;
        this._instance = _instance;
        this.getWebExperimentsAndEvaluateDisplayLogic = function (forceReload) {
            if (forceReload === void 0) { forceReload = false; }
            _this.getWebExperiments(function (webExperiments) {
                WebExperiments._logInfo("retrieved web experiments from the server");
                _this._flagToExperiments = new Map();
                webExperiments.forEach(function (webExperiment) {
                    var _a;
                    if (webExperiment.feature_flag_key) {
                        if (_this._flagToExperiments) {
                            WebExperiments._logInfo("setting flag key ", webExperiment.feature_flag_key, " to web experiment ", webExperiment);
                            (_a = _this._flagToExperiments) === null || _a === void 0 ? void 0 : _a.set(webExperiment.feature_flag_key, webExperiment);
                        }
                        var selectedVariant = _this._instance.getFeatureFlag(webExperiment.feature_flag_key);
                        if ((0, core_1.isString)(selectedVariant) && webExperiment.variants[selectedVariant]) {
                            _this._applyTransforms(webExperiment.name, selectedVariant, webExperiment.variants[selectedVariant].transforms);
                        }
                    }
                    else if (webExperiment.variants) {
                        for (var variant in webExperiment.variants) {
                            var testVariant = webExperiment.variants[variant];
                            var matchTest = WebExperiments._matchesTestVariant(testVariant);
                            if (matchTest) {
                                _this._applyTransforms(webExperiment.name, variant, testVariant.transforms);
                            }
                        }
                    }
                });
            }, forceReload);
        };
        this._instance.onFeatureFlags(function (flags) {
            _this.onFeatureFlags(flags);
        });
    }
    WebExperiments.prototype.onFeatureFlags = function (flags) {
        var _this = this;
        if (this._is_bot()) {
            WebExperiments._logInfo('Refusing to render web experiment since the viewer is a likely bot');
            return;
        }
        if (this._instance.config.disable_web_experiments) {
            return;
        }
        if ((0, core_1.isNullish)(this._flagToExperiments)) {
            // Indicates first load so we trigger the loaders
            this._flagToExperiments = new Map();
            this.loadIfEnabled();
            this.previewWebExperiment();
            return;
        }
        WebExperiments._logInfo('applying feature flags', flags);
        flags.forEach(function (flag) {
            var _a, _b;
            if (_this._flagToExperiments && ((_a = _this._flagToExperiments) === null || _a === void 0 ? void 0 : _a.has(flag))) {
                var selectedVariant = _this._instance.getFeatureFlag(flag);
                var webExperiment = (_b = _this._flagToExperiments) === null || _b === void 0 ? void 0 : _b.get(flag);
                if (selectedVariant && (webExperiment === null || webExperiment === void 0 ? void 0 : webExperiment.variants[selectedVariant])) {
                    _this._applyTransforms(webExperiment.name, selectedVariant, webExperiment.variants[selectedVariant].transforms);
                }
            }
        });
    };
    WebExperiments.prototype.previewWebExperiment = function () {
        var _this = this;
        var location = WebExperiments.getWindowLocation();
        if (location === null || location === void 0 ? void 0 : location.search) {
            var experimentID_1 = (0, request_utils_1.getQueryParam)(location === null || location === void 0 ? void 0 : location.search, '__experiment_id');
            var variant_1 = (0, request_utils_1.getQueryParam)(location === null || location === void 0 ? void 0 : location.search, '__experiment_variant');
            if (experimentID_1 && variant_1) {
                WebExperiments._logInfo("previewing web experiments ".concat(experimentID_1, " && ").concat(variant_1));
                this.getWebExperiments(function (webExperiments) {
                    _this._showPreviewWebExperiment(parseInt(experimentID_1), variant_1, webExperiments);
                }, false, true);
            }
        }
    };
    WebExperiments.prototype.loadIfEnabled = function () {
        if (this._instance.config.disable_web_experiments) {
            return;
        }
        this.getWebExperimentsAndEvaluateDisplayLogic();
    };
    WebExperiments.prototype.getWebExperiments = function (callback, forceReload, previewing) {
        if (this._instance.config.disable_web_experiments && !previewing) {
            return callback([]);
        }
        var existingWebExperiments = this._instance.get_property(constants_1.WEB_EXPERIMENTS);
        if (existingWebExperiments && !forceReload) {
            return callback(existingWebExperiments);
        }
        this._instance._send_request({
            url: this._instance.requestRouter.endpointFor('api', "/api/web_experiments/?token=".concat(this._instance.config.token)),
            method: 'GET',
            callback: function (response) {
                if (response.statusCode !== 200 || !response.json) {
                    return callback([]);
                }
                var webExperiments = response.json.experiments || [];
                return callback(webExperiments);
            },
        });
    };
    WebExperiments.prototype._showPreviewWebExperiment = function (experimentID, variant, webExperiments) {
        var previewExperiments = webExperiments.filter(function (exp) { return exp.id === experimentID; });
        if (previewExperiments && previewExperiments.length > 0) {
            WebExperiments._logInfo("Previewing web experiment [".concat(previewExperiments[0].name, "] with variant [").concat(variant, "]"));
            this._applyTransforms(previewExperiments[0].name, variant, previewExperiments[0].variants[variant].transforms);
        }
    };
    WebExperiments._matchesTestVariant = function (testVariant) {
        if ((0, core_1.isNullish)(testVariant.conditions)) {
            return false;
        }
        return WebExperiments._matchUrlConditions(testVariant) && WebExperiments._matchUTMConditions(testVariant);
    };
    WebExperiments._matchUrlConditions = function (testVariant) {
        var _a, _b, _c, _d;
        if ((0, core_1.isNullish)(testVariant.conditions) || (0, core_1.isNullish)((_a = testVariant.conditions) === null || _a === void 0 ? void 0 : _a.url)) {
            return true;
        }
        var location = WebExperiments.getWindowLocation();
        if (location) {
            var urlCheck = ((_b = testVariant.conditions) === null || _b === void 0 ? void 0 : _b.url)
                ? exports.webExperimentUrlValidationMap[(_d = (_c = testVariant.conditions) === null || _c === void 0 ? void 0 : _c.urlMatchType) !== null && _d !== void 0 ? _d : 'icontains'](testVariant.conditions.url, location)
                : true;
            return urlCheck;
        }
        return false;
    };
    WebExperiments.getWindowLocation = function () {
        return globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.location;
    };
    WebExperiments._matchUTMConditions = function (testVariant) {
        var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r, _s;
        if ((0, core_1.isNullish)(testVariant.conditions) || (0, core_1.isNullish)((_a = testVariant.conditions) === null || _a === void 0 ? void 0 : _a.utm)) {
            return true;
        }
        var campaignParams = (0, event_utils_1.getCampaignParams)();
        if (campaignParams['utm_source']) {
            // eslint-disable-next-line compat/compat
            var utmCampaignMatched = ((_c = (_b = testVariant.conditions) === null || _b === void 0 ? void 0 : _b.utm) === null || _c === void 0 ? void 0 : _c.utm_campaign)
                ? ((_e = (_d = testVariant.conditions) === null || _d === void 0 ? void 0 : _d.utm) === null || _e === void 0 ? void 0 : _e.utm_campaign) == campaignParams['utm_campaign']
                : true;
            var utmSourceMatched = ((_g = (_f = testVariant.conditions) === null || _f === void 0 ? void 0 : _f.utm) === null || _g === void 0 ? void 0 : _g.utm_source)
                ? ((_j = (_h = testVariant.conditions) === null || _h === void 0 ? void 0 : _h.utm) === null || _j === void 0 ? void 0 : _j.utm_source) == campaignParams['utm_source']
                : true;
            var utmMediumMatched = ((_l = (_k = testVariant.conditions) === null || _k === void 0 ? void 0 : _k.utm) === null || _l === void 0 ? void 0 : _l.utm_medium)
                ? ((_o = (_m = testVariant.conditions) === null || _m === void 0 ? void 0 : _m.utm) === null || _o === void 0 ? void 0 : _o.utm_medium) == campaignParams['utm_medium']
                : true;
            var utmTermMatched = ((_q = (_p = testVariant.conditions) === null || _p === void 0 ? void 0 : _p.utm) === null || _q === void 0 ? void 0 : _q.utm_term)
                ? ((_s = (_r = testVariant.conditions) === null || _r === void 0 ? void 0 : _r.utm) === null || _s === void 0 ? void 0 : _s.utm_term) == campaignParams['utm_term']
                : true;
            return utmCampaignMatched && utmMediumMatched && utmTermMatched && utmSourceMatched;
        }
        return false;
    };
    WebExperiments._logInfo = function (msg) {
        var args = [];
        for (var _i = 1; _i < arguments.length; _i++) {
            args[_i - 1] = arguments[_i];
        }
        logger_1.logger.info("[WebExperiments] ".concat(msg), args);
    };
    WebExperiments.prototype._applyTransforms = function (experiment, variant, transforms) {
        if (this._is_bot()) {
            WebExperiments._logInfo('Refusing to render web experiment since the viewer is a likely bot');
            return;
        }
        if (variant === 'control') {
            WebExperiments._logInfo('Control variants leave the page unmodified.');
            return;
        }
        transforms.forEach(function (transform) {
            if (transform.selector) {
                WebExperiments._logInfo("applying transform of variant ".concat(variant, " for experiment ").concat(experiment, " "), transform);
                // eslint-disable-next-line no-restricted-globals
                var elements = document === null || document === void 0 ? void 0 : document.querySelectorAll(transform.selector);
                elements === null || elements === void 0 ? void 0 : elements.forEach(function (element) {
                    var htmlElement = element;
                    if (transform.html) {
                        htmlElement.innerHTML = transform.html;
                    }
                    if (transform.css) {
                        htmlElement.setAttribute('style', transform.css);
                    }
                });
            }
        });
    };
    WebExperiments.prototype._is_bot = function () {
        if (globals_1.navigator && this._instance) {
            return (0, blocked_uas_1.isLikelyBot)(globals_1.navigator, this._instance.config.custom_blocked_useragents);
        }
        else {
            return undefined;
        }
    };
    return WebExperiments;
}());
exports.WebExperiments = WebExperiments;
//# sourceMappingURL=web-experiments.js.map