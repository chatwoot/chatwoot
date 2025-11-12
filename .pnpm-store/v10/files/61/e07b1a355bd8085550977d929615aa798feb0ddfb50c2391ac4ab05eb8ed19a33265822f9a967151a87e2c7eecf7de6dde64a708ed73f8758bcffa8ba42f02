"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.PostHogSurveys = void 0;
var constants_1 = require("./constants");
var globals_1 = require("./utils/globals");
var survey_event_receiver_1 = require("./utils/survey-event-receiver");
var survey_utils_1 = require("./utils/survey-utils");
var core_1 = require("@posthog/core");
var PostHogSurveys = /** @class */ (function () {
    function PostHogSurveys(_instance) {
        this._instance = _instance;
        // this is set to undefined until the remote config is loaded
        // then it's set to true if there are surveys to load
        // or false if there are no surveys to load
        // or false if the surveys feature is disabled in the project settings
        this._isSurveysEnabled = undefined;
        this._surveyManager = null;
        this._isFetchingSurveys = false;
        this._isInitializingSurveys = false;
        this._surveyCallbacks = [];
        // we set this to undefined here because we need the persistence storage for this type
        // but that's not initialized until loadIfEnabled is called.
        this._surveyEventReceiver = null;
    }
    PostHogSurveys.prototype.onRemoteConfig = function (response) {
        // only load surveys if they are enabled and there are surveys to load
        var surveys = response['surveys'];
        if ((0, core_1.isNullish)(surveys)) {
            return survey_utils_1.SURVEY_LOGGER.warn('Flags not loaded yet. Not loading surveys.');
        }
        var isArrayResponse = (0, core_1.isArray)(surveys);
        this._isSurveysEnabled = isArrayResponse ? surveys.length > 0 : surveys;
        survey_utils_1.SURVEY_LOGGER.info("flags response received, isSurveysEnabled: ".concat(this._isSurveysEnabled));
        this.loadIfEnabled();
    };
    PostHogSurveys.prototype.reset = function () {
        localStorage.removeItem('lastSeenSurveyDate');
        var surveyKeys = [];
        for (var i = 0; i < localStorage.length; i++) {
            var key = localStorage.key(i);
            if ((key === null || key === void 0 ? void 0 : key.startsWith(survey_utils_1.SURVEY_SEEN_PREFIX)) || (key === null || key === void 0 ? void 0 : key.startsWith(survey_utils_1.SURVEY_IN_PROGRESS_PREFIX))) {
                surveyKeys.push(key);
            }
        }
        surveyKeys.forEach(function (key) { return localStorage.removeItem(key); });
    };
    PostHogSurveys.prototype.loadIfEnabled = function () {
        var _this = this;
        // Initial guard clauses
        if (this._surveyManager) {
            return;
        } // Already loaded
        if (this._isInitializingSurveys) {
            survey_utils_1.SURVEY_LOGGER.info('Already initializing surveys, skipping...');
            return;
        }
        if (this._instance.config.disable_surveys) {
            survey_utils_1.SURVEY_LOGGER.info('Disabled. Not loading surveys.');
            return;
        }
        if (this._instance.config.cookieless_mode) {
            survey_utils_1.SURVEY_LOGGER.info('Not loading surveys in cookieless mode.');
            return;
        }
        var phExtensions = globals_1.assignableWindow === null || globals_1.assignableWindow === void 0 ? void 0 : globals_1.assignableWindow.__PosthogExtensions__;
        if (!phExtensions) {
            survey_utils_1.SURVEY_LOGGER.error('PostHog Extensions not found.');
            return;
        }
        // waiting for remote config to load
        // if surveys is forced enable (like external surveys), ignore the remote config and load surveys
        if ((0, core_1.isUndefined)(this._isSurveysEnabled) && !this._instance.config.advanced_enable_surveys) {
            return;
        }
        var isSurveysEnabled = this._isSurveysEnabled || this._instance.config.advanced_enable_surveys;
        this._isInitializingSurveys = true;
        try {
            var generateSurveys = phExtensions.generateSurveys;
            if (generateSurveys) {
                // Surveys code is already loaded
                this._completeSurveyInitialization(generateSurveys, isSurveysEnabled);
                return;
            }
            // If we reach here, surveys code is not loaded yet
            var loadExternalDependency = phExtensions.loadExternalDependency;
            if (!loadExternalDependency) {
                // Cannot load surveys code
                this._handleSurveyLoadError('PostHog loadExternalDependency extension not found.');
                return;
            }
            // If we reach here, we need to load the dependency
            loadExternalDependency(this._instance, 'surveys', function (err) {
                if (err || !phExtensions.generateSurveys) {
                    _this._handleSurveyLoadError('Could not load surveys script', err);
                }
                else {
                    // Need to get the function reference again inside the callback
                    _this._completeSurveyInitialization(phExtensions.generateSurveys, isSurveysEnabled);
                }
            });
        }
        catch (e) {
            this._handleSurveyLoadError('Error initializing surveys', e);
            throw e;
        }
        finally {
            // Ensure the flag is always reset
            this._isInitializingSurveys = false;
        }
    };
    /** Helper to finalize survey initialization */
    PostHogSurveys.prototype._completeSurveyInitialization = function (generateSurveysFn, isSurveysEnabled) {
        this._surveyManager = generateSurveysFn(this._instance, isSurveysEnabled);
        this._surveyEventReceiver = new survey_event_receiver_1.SurveyEventReceiver(this._instance);
        survey_utils_1.SURVEY_LOGGER.info('Surveys loaded successfully');
        this._notifySurveyCallbacks({ isLoaded: true });
    };
    /** Helper to handle errors during survey loading */
    PostHogSurveys.prototype._handleSurveyLoadError = function (message, error) {
        survey_utils_1.SURVEY_LOGGER.error(message, error);
        this._notifySurveyCallbacks({ isLoaded: false, error: message });
    };
    /**
     * Register a callback that runs when surveys are initialized.
     * ### Usage:
     *
     *     posthog.onSurveysLoaded((surveys) => {
     *         // You can work with all surveys
     *         console.log('All available surveys:', surveys)
     *
     *         // Or get active matching surveys
     *         posthog.getActiveMatchingSurveys((activeMatchingSurveys) => {
     *             if (activeMatchingSurveys.length > 0) {
     *                 posthog.renderSurvey(activeMatchingSurveys[0].id, '#survey-container')
     *             }
     *         })
     *     })
     *
     * @param {Function} callback The callback function will be called when surveys are loaded or updated.
     *                           It receives the array of all surveys and a context object with error status.
     * @returns {Function} A function that can be called to unsubscribe the listener.
     */
    PostHogSurveys.prototype.onSurveysLoaded = function (callback) {
        var _this = this;
        this._surveyCallbacks.push(callback);
        if (this._surveyManager) {
            this._notifySurveyCallbacks({
                isLoaded: true,
            });
        }
        // Return unsubscribe function
        return function () {
            _this._surveyCallbacks = _this._surveyCallbacks.filter(function (cb) { return cb !== callback; });
        };
    };
    PostHogSurveys.prototype.getSurveys = function (callback, forceReload) {
        var _this = this;
        if (forceReload === void 0) { forceReload = false; }
        // In case we manage to load the surveys script, but config says not to load surveys
        // then we shouldn't return survey data
        if (this._instance.config.disable_surveys) {
            survey_utils_1.SURVEY_LOGGER.info('Disabled. Not loading surveys.');
            return callback([]);
        }
        var existingSurveys = this._instance.get_property(constants_1.SURVEYS);
        if (existingSurveys && !forceReload) {
            return callback(existingSurveys, {
                isLoaded: true,
            });
        }
        // Prevent concurrent API calls
        if (this._isFetchingSurveys) {
            return callback([], {
                isLoaded: false,
                error: 'Surveys are already being loaded',
            });
        }
        try {
            this._isFetchingSurveys = true;
            this._instance._send_request({
                url: this._instance.requestRouter.endpointFor('api', "/api/surveys/?token=".concat(this._instance.config.token)),
                method: 'GET',
                timeout: this._instance.config.surveys_request_timeout_ms,
                callback: function (response) {
                    var _a;
                    var _b, _c;
                    _this._isFetchingSurveys = false;
                    var statusCode = response.statusCode;
                    if (statusCode !== 200 || !response.json) {
                        var error = "Surveys API could not be loaded, status: ".concat(statusCode);
                        survey_utils_1.SURVEY_LOGGER.error(error);
                        return callback([], {
                            isLoaded: false,
                            error: error,
                        });
                    }
                    var surveys = response.json.surveys || [];
                    var eventOrActionBasedSurveys = surveys.filter(function (survey) {
                        return (0, survey_utils_1.isSurveyRunning)(survey) &&
                            ((0, survey_utils_1.doesSurveyActivateByEvent)(survey) || (0, survey_utils_1.doesSurveyActivateByAction)(survey));
                    });
                    if (eventOrActionBasedSurveys.length > 0) {
                        (_b = _this._surveyEventReceiver) === null || _b === void 0 ? void 0 : _b.register(eventOrActionBasedSurveys);
                    }
                    (_c = _this._instance.persistence) === null || _c === void 0 ? void 0 : _c.register((_a = {}, _a[constants_1.SURVEYS] = surveys, _a));
                    return callback(surveys, {
                        isLoaded: true,
                    });
                },
            });
        }
        catch (e) {
            this._isFetchingSurveys = false;
            throw e;
        }
    };
    /** Helper method to notify all registered callbacks */
    PostHogSurveys.prototype._notifySurveyCallbacks = function (context) {
        var e_1, _a;
        try {
            for (var _b = __values(this._surveyCallbacks), _c = _b.next(); !_c.done; _c = _b.next()) {
                var callback = _c.value;
                try {
                    if (!context.isLoaded) {
                        return callback([], context);
                    }
                    this.getSurveys(callback);
                }
                catch (error) {
                    survey_utils_1.SURVEY_LOGGER.error('Error in survey callback', error);
                }
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (_c && !_c.done && (_a = _b.return)) _a.call(_b);
            }
            finally { if (e_1) throw e_1.error; }
        }
    };
    PostHogSurveys.prototype.getActiveMatchingSurveys = function (callback, forceReload) {
        if (forceReload === void 0) { forceReload = false; }
        if ((0, core_1.isNullish)(this._surveyManager)) {
            survey_utils_1.SURVEY_LOGGER.warn('init was not called');
            return;
        }
        return this._surveyManager.getActiveMatchingSurveys(callback, forceReload);
    };
    PostHogSurveys.prototype._getSurveyById = function (surveyId) {
        var survey = null;
        this.getSurveys(function (surveys) {
            var _a;
            survey = (_a = surveys.find(function (x) { return x.id === surveyId; })) !== null && _a !== void 0 ? _a : null;
        });
        return survey;
    };
    PostHogSurveys.prototype._checkSurveyEligibility = function (surveyId) {
        if ((0, core_1.isNullish)(this._surveyManager)) {
            return { eligible: false, reason: 'SDK is not enabled or survey functionality is not yet loaded' };
        }
        var survey = typeof surveyId === 'string' ? this._getSurveyById(surveyId) : surveyId;
        if (!survey) {
            return { eligible: false, reason: 'Survey not found' };
        }
        return this._surveyManager.checkSurveyEligibility(survey);
    };
    PostHogSurveys.prototype.canRenderSurvey = function (surveyId) {
        if ((0, core_1.isNullish)(this._surveyManager)) {
            survey_utils_1.SURVEY_LOGGER.warn('init was not called');
            return { visible: false, disabledReason: 'SDK is not enabled or survey functionality is not yet loaded' };
        }
        var eligibility = this._checkSurveyEligibility(surveyId);
        return { visible: eligibility.eligible, disabledReason: eligibility.reason };
    };
    PostHogSurveys.prototype.canRenderSurveyAsync = function (surveyId, forceReload) {
        var _this = this;
        // Ensure surveys are loaded before checking
        // Using Promise to wrap the callback-based getSurveys method
        if ((0, core_1.isNullish)(this._surveyManager)) {
            survey_utils_1.SURVEY_LOGGER.warn('init was not called');
            return Promise.resolve({
                visible: false,
                disabledReason: 'SDK is not enabled or survey functionality is not yet loaded',
            });
        }
        // eslint-disable-next-line compat/compat
        return new Promise(function (resolve) {
            _this.getSurveys(function (surveys) {
                var _a;
                var survey = (_a = surveys.find(function (x) { return x.id === surveyId; })) !== null && _a !== void 0 ? _a : null;
                if (!survey) {
                    resolve({ visible: false, disabledReason: 'Survey not found' });
                }
                else {
                    var eligibility = _this._checkSurveyEligibility(survey);
                    resolve({ visible: eligibility.eligible, disabledReason: eligibility.reason });
                }
            }, forceReload);
        });
    };
    PostHogSurveys.prototype.renderSurvey = function (surveyId, selector) {
        if ((0, core_1.isNullish)(this._surveyManager)) {
            survey_utils_1.SURVEY_LOGGER.warn('init was not called');
            return;
        }
        var survey = this._getSurveyById(surveyId);
        if (!survey) {
            survey_utils_1.SURVEY_LOGGER.warn('Survey not found');
            return;
        }
        if (!survey_utils_1.IN_APP_SURVEY_TYPES.includes(survey.type)) {
            survey_utils_1.SURVEY_LOGGER.warn("Surveys of type ".concat(survey.type, " cannot be rendered in the app"));
            return;
            return;
        }
        var elem = globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.querySelector(selector);
        if (!elem) {
            survey_utils_1.SURVEY_LOGGER.warn('Survey element not found');
            return;
        }
        this._surveyManager.renderSurvey(survey, elem);
    };
    return PostHogSurveys;
}());
exports.PostHogSurveys = PostHogSurveys;
//# sourceMappingURL=posthog-surveys.js.map