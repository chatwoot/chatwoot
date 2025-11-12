"use strict";
var __webpack_modules__ = {
    "./eventemitter": function(module) {
        module.exports = require("./eventemitter.js");
    },
    "./featureFlagUtils": function(module) {
        module.exports = require("./featureFlagUtils.js");
    },
    "./gzip": function(module) {
        module.exports = require("./gzip.js");
    },
    "./types": function(module) {
        module.exports = require("./types.js");
    },
    "./utils": function(module) {
        module.exports = require("./utils/index.js");
    },
    "./vendor/uuidv7": function(module) {
        module.exports = require("./vendor/uuidv7.js");
    }
};
var __webpack_module_cache__ = {};
function __webpack_require__(moduleId) {
    var cachedModule = __webpack_module_cache__[moduleId];
    if (void 0 !== cachedModule) return cachedModule.exports;
    var module = __webpack_module_cache__[moduleId] = {
        exports: {}
    };
    __webpack_modules__[moduleId](module, module.exports, __webpack_require__);
    return module.exports;
}
(()=>{
    __webpack_require__.n = (module)=>{
        var getter = module && module.__esModule ? ()=>module['default'] : ()=>module;
        __webpack_require__.d(getter, {
            a: getter
        });
        return getter;
    };
})();
(()=>{
    __webpack_require__.d = (exports1, definition)=>{
        for(var key in definition)if (__webpack_require__.o(definition, key) && !__webpack_require__.o(exports1, key)) Object.defineProperty(exports1, key, {
            enumerable: true,
            get: definition[key]
        });
    };
})();
(()=>{
    __webpack_require__.o = (obj, prop)=>Object.prototype.hasOwnProperty.call(obj, prop);
})();
(()=>{
    __webpack_require__.r = (exports1)=>{
        if ('undefined' != typeof Symbol && Symbol.toStringTag) Object.defineProperty(exports1, Symbol.toStringTag, {
            value: 'Module'
        });
        Object.defineProperty(exports1, '__esModule', {
            value: true
        });
    };
})();
var __webpack_exports__ = {};
(()=>{
    __webpack_require__.r(__webpack_exports__);
    __webpack_require__.d(__webpack_exports__, {
        PostHogCore: ()=>PostHogCore,
        PostHogCoreStateless: ()=>PostHogCoreStateless,
        getFeatureFlagValue: ()=>_featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.getFeatureFlagValue,
        logFlushError: ()=>logFlushError,
        maybeAdd: ()=>maybeAdd
    });
    var _types__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__("./types");
    var _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__("./featureFlagUtils");
    var _utils__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__("./utils");
    var _gzip__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__("./gzip");
    var _eventemitter__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__("./eventemitter");
    var _vendor_uuidv7__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__("./vendor/uuidv7");
    var __WEBPACK_REEXPORT_OBJECT__ = {};
    for(var __WEBPACK_IMPORT_KEY__ in _utils__WEBPACK_IMPORTED_MODULE_2__)if ([
        "default",
        "maybeAdd",
        "logFlushError",
        "getFeatureFlagValue",
        "PostHogCoreStateless",
        "PostHogCore"
    ].indexOf(__WEBPACK_IMPORT_KEY__) < 0) __WEBPACK_REEXPORT_OBJECT__[__WEBPACK_IMPORT_KEY__] = (function(key) {
        return _utils__WEBPACK_IMPORTED_MODULE_2__[key];
    }).bind(0, __WEBPACK_IMPORT_KEY__);
    __webpack_require__.d(__webpack_exports__, __WEBPACK_REEXPORT_OBJECT__);
    var __WEBPACK_REEXPORT_OBJECT__ = {};
    for(var __WEBPACK_IMPORT_KEY__ in _types__WEBPACK_IMPORTED_MODULE_0__)if ([
        "default",
        "maybeAdd",
        "logFlushError",
        "getFeatureFlagValue",
        "PostHogCoreStateless",
        "PostHogCore"
    ].indexOf(__WEBPACK_IMPORT_KEY__) < 0) __WEBPACK_REEXPORT_OBJECT__[__WEBPACK_IMPORT_KEY__] = (function(key) {
        return _types__WEBPACK_IMPORTED_MODULE_0__[key];
    }).bind(0, __WEBPACK_IMPORT_KEY__);
    __webpack_require__.d(__webpack_exports__, __WEBPACK_REEXPORT_OBJECT__);
    class PostHogFetchHttpError extends Error {
        get status() {
            return this.response.status;
        }
        get text() {
            return this.response.text();
        }
        get json() {
            return this.response.json();
        }
        constructor(response, reqByteLength){
            super('HTTP error while fetching PostHog: status=' + response.status + ', reqByteLength=' + reqByteLength), this.response = response, this.reqByteLength = reqByteLength, this.name = 'PostHogFetchHttpError';
        }
    }
    class PostHogFetchNetworkError extends Error {
        constructor(error){
            super('Network error while fetching PostHog', error instanceof Error ? {
                cause: error
            } : {}), this.error = error, this.name = 'PostHogFetchNetworkError';
        }
    }
    const maybeAdd = (key, value)=>void 0 !== value ? {
            [key]: value
        } : {};
    async function logFlushError(err) {
        if (err instanceof PostHogFetchHttpError) {
            let text = '';
            try {
                text = await err.text;
            } catch (e) {}
            console.error(`Error while flushing PostHog: message=${err.message}, response body=${text}`, err);
        } else console.error('Error while flushing PostHog', err);
        return Promise.resolve();
    }
    function isPostHogFetchError(err) {
        return 'object' == typeof err && (err instanceof PostHogFetchHttpError || err instanceof PostHogFetchNetworkError);
    }
    function isPostHogFetchContentTooLargeError(err) {
        return 'object' == typeof err && err instanceof PostHogFetchHttpError && 413 === err.status;
    }
    class PostHogCoreStateless {
        logMsgIfDebug(fn) {
            if (this.isDebug) fn();
        }
        wrap(fn) {
            if (this.disabled) return void this.logMsgIfDebug(()=>console.warn('[PostHog] The client is disabled'));
            if (this._isInitialized) return fn();
            this._initPromise.then(()=>fn());
        }
        getCommonEventProperties() {
            return {
                $lib: this.getLibraryId(),
                $lib_version: this.getLibraryVersion()
            };
        }
        get optedOut() {
            var _this_getPersistedProperty;
            return null != (_this_getPersistedProperty = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.OptedOut)) ? _this_getPersistedProperty : !this.defaultOptIn;
        }
        async optIn() {
            this.wrap(()=>{
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.OptedOut, false);
            });
        }
        async optOut() {
            this.wrap(()=>{
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.OptedOut, true);
            });
        }
        on(event, cb) {
            return this._events.on(event, cb);
        }
        debug() {
            let enabled = arguments.length > 0 && void 0 !== arguments[0] ? arguments[0] : true;
            var _this_removeDebugCallback, _this;
            null == (_this_removeDebugCallback = (_this = this).removeDebugCallback) || _this_removeDebugCallback.call(_this);
            if (enabled) {
                const removeDebugCallback = this.on('*', (event, payload)=>console.log('PostHog Debug', event, payload));
                this.removeDebugCallback = ()=>{
                    removeDebugCallback();
                    this.removeDebugCallback = void 0;
                };
            }
        }
        get isDebug() {
            return !!this.removeDebugCallback;
        }
        get isDisabled() {
            return this.disabled;
        }
        buildPayload(payload) {
            return {
                distinct_id: payload.distinct_id,
                event: payload.event,
                properties: {
                    ...payload.properties || {},
                    ...this.getCommonEventProperties()
                }
            };
        }
        addPendingPromise(promise) {
            const promiseUUID = (0, _vendor_uuidv7__WEBPACK_IMPORTED_MODULE_5__.uuidv7)();
            this.pendingPromises[promiseUUID] = promise;
            promise.catch(()=>{}).finally(()=>{
                delete this.pendingPromises[promiseUUID];
            });
            return promise;
        }
        identifyStateless(distinctId, properties, options) {
            this.wrap(()=>{
                const payload = {
                    ...this.buildPayload({
                        distinct_id: distinctId,
                        event: '$identify',
                        properties
                    })
                };
                this.enqueue('identify', payload, options);
            });
        }
        async identifyStatelessImmediate(distinctId, properties, options) {
            const payload = {
                ...this.buildPayload({
                    distinct_id: distinctId,
                    event: '$identify',
                    properties
                })
            };
            await this.sendImmediate('identify', payload, options);
        }
        captureStateless(distinctId, event, properties, options) {
            this.wrap(()=>{
                const payload = this.buildPayload({
                    distinct_id: distinctId,
                    event,
                    properties
                });
                this.enqueue('capture', payload, options);
            });
        }
        async captureStatelessImmediate(distinctId, event, properties, options) {
            const payload = this.buildPayload({
                distinct_id: distinctId,
                event,
                properties
            });
            await this.sendImmediate('capture', payload, options);
        }
        aliasStateless(alias, distinctId, properties, options) {
            this.wrap(()=>{
                const payload = this.buildPayload({
                    event: '$create_alias',
                    distinct_id: distinctId,
                    properties: {
                        ...properties || {},
                        distinct_id: distinctId,
                        alias
                    }
                });
                this.enqueue('alias', payload, options);
            });
        }
        async aliasStatelessImmediate(alias, distinctId, properties, options) {
            const payload = this.buildPayload({
                event: '$create_alias',
                distinct_id: distinctId,
                properties: {
                    ...properties || {},
                    distinct_id: distinctId,
                    alias
                }
            });
            await this.sendImmediate('alias', payload, options);
        }
        groupIdentifyStateless(groupType, groupKey, groupProperties, options, distinctId, eventProperties) {
            this.wrap(()=>{
                const payload = this.buildPayload({
                    distinct_id: distinctId || `$${groupType}_${groupKey}`,
                    event: '$groupidentify',
                    properties: {
                        $group_type: groupType,
                        $group_key: groupKey,
                        $group_set: groupProperties || {},
                        ...eventProperties || {}
                    }
                });
                this.enqueue('capture', payload, options);
            });
        }
        async getRemoteConfig() {
            await this._initPromise;
            let host = this.host;
            if ('https://us.i.posthog.com' === host) host = 'https://us-assets.i.posthog.com';
            else if ('https://eu.i.posthog.com' === host) host = 'https://eu-assets.i.posthog.com';
            const url = `${host}/array/${this.apiKey}/config`;
            const fetchOptions = {
                method: 'GET',
                headers: {
                    ...this.getCustomHeaders(),
                    'Content-Type': 'application/json'
                }
            };
            return this.fetchWithRetry(url, fetchOptions, {
                retryCount: 0
            }, this.remoteConfigRequestTimeoutMs).then((response)=>response.json()).catch((error)=>{
                this.logMsgIfDebug(()=>console.error('Remote config could not be loaded', error));
                this._events.emit('error', error);
            });
        }
        async getFlags(distinctId) {
            let groups = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : {}, personProperties = arguments.length > 2 && void 0 !== arguments[2] ? arguments[2] : {}, groupProperties = arguments.length > 3 && void 0 !== arguments[3] ? arguments[3] : {}, extraPayload = arguments.length > 4 && void 0 !== arguments[4] ? arguments[4] : {};
            await this._initPromise;
            const url = `${this.host}/flags/?v=2&config=true`;
            const fetchOptions = {
                method: 'POST',
                headers: {
                    ...this.getCustomHeaders(),
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    token: this.apiKey,
                    distinct_id: distinctId,
                    groups,
                    person_properties: personProperties,
                    group_properties: groupProperties,
                    ...extraPayload
                })
            };
            this.logMsgIfDebug(()=>console.log('PostHog Debug', 'Flags URL', url));
            return this.fetchWithRetry(url, fetchOptions, {
                retryCount: 0
            }, this.featureFlagsRequestTimeoutMs).then((response)=>response.json()).then((response)=>(0, _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.normalizeFlagsResponse)(response)).catch((error)=>{
                this._events.emit('error', error);
            });
        }
        async getFeatureFlagStateless(key, distinctId) {
            let groups = arguments.length > 2 && void 0 !== arguments[2] ? arguments[2] : {}, personProperties = arguments.length > 3 && void 0 !== arguments[3] ? arguments[3] : {}, groupProperties = arguments.length > 4 && void 0 !== arguments[4] ? arguments[4] : {}, disableGeoip = arguments.length > 5 ? arguments[5] : void 0;
            await this._initPromise;
            const flagDetailResponse = await this.getFeatureFlagDetailStateless(key, distinctId, groups, personProperties, groupProperties, disableGeoip);
            if (void 0 === flagDetailResponse) return {
                response: void 0,
                requestId: void 0
            };
            let response = (0, _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.getFeatureFlagValue)(flagDetailResponse.response);
            if (void 0 === response) response = false;
            return {
                response,
                requestId: flagDetailResponse.requestId
            };
        }
        async getFeatureFlagDetailStateless(key, distinctId) {
            let groups = arguments.length > 2 && void 0 !== arguments[2] ? arguments[2] : {}, personProperties = arguments.length > 3 && void 0 !== arguments[3] ? arguments[3] : {}, groupProperties = arguments.length > 4 && void 0 !== arguments[4] ? arguments[4] : {}, disableGeoip = arguments.length > 5 ? arguments[5] : void 0;
            await this._initPromise;
            const flagsResponse = await this.getFeatureFlagDetailsStateless(distinctId, groups, personProperties, groupProperties, disableGeoip, [
                key
            ]);
            if (void 0 === flagsResponse) return;
            const featureFlags = flagsResponse.flags;
            const flagDetail = featureFlags[key];
            return {
                response: flagDetail,
                requestId: flagsResponse.requestId
            };
        }
        async getFeatureFlagPayloadStateless(key, distinctId) {
            let groups = arguments.length > 2 && void 0 !== arguments[2] ? arguments[2] : {}, personProperties = arguments.length > 3 && void 0 !== arguments[3] ? arguments[3] : {}, groupProperties = arguments.length > 4 && void 0 !== arguments[4] ? arguments[4] : {}, disableGeoip = arguments.length > 5 ? arguments[5] : void 0;
            await this._initPromise;
            const payloads = await this.getFeatureFlagPayloadsStateless(distinctId, groups, personProperties, groupProperties, disableGeoip, [
                key
            ]);
            if (!payloads) return;
            const response = payloads[key];
            if (void 0 === response) return null;
            return response;
        }
        async getFeatureFlagPayloadsStateless(distinctId) {
            let groups = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : {}, personProperties = arguments.length > 2 && void 0 !== arguments[2] ? arguments[2] : {}, groupProperties = arguments.length > 3 && void 0 !== arguments[3] ? arguments[3] : {}, disableGeoip = arguments.length > 4 ? arguments[4] : void 0, flagKeysToEvaluate = arguments.length > 5 ? arguments[5] : void 0;
            await this._initPromise;
            const payloads = (await this.getFeatureFlagsAndPayloadsStateless(distinctId, groups, personProperties, groupProperties, disableGeoip, flagKeysToEvaluate)).payloads;
            return payloads;
        }
        async getFeatureFlagsStateless(distinctId) {
            let groups = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : {}, personProperties = arguments.length > 2 && void 0 !== arguments[2] ? arguments[2] : {}, groupProperties = arguments.length > 3 && void 0 !== arguments[3] ? arguments[3] : {}, disableGeoip = arguments.length > 4 ? arguments[4] : void 0, flagKeysToEvaluate = arguments.length > 5 ? arguments[5] : void 0;
            await this._initPromise;
            return await this.getFeatureFlagsAndPayloadsStateless(distinctId, groups, personProperties, groupProperties, disableGeoip, flagKeysToEvaluate);
        }
        async getFeatureFlagsAndPayloadsStateless(distinctId) {
            let groups = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : {}, personProperties = arguments.length > 2 && void 0 !== arguments[2] ? arguments[2] : {}, groupProperties = arguments.length > 3 && void 0 !== arguments[3] ? arguments[3] : {}, disableGeoip = arguments.length > 4 ? arguments[4] : void 0, flagKeysToEvaluate = arguments.length > 5 ? arguments[5] : void 0;
            await this._initPromise;
            const featureFlagDetails = await this.getFeatureFlagDetailsStateless(distinctId, groups, personProperties, groupProperties, disableGeoip, flagKeysToEvaluate);
            if (!featureFlagDetails) return {
                flags: void 0,
                payloads: void 0,
                requestId: void 0
            };
            return {
                flags: featureFlagDetails.featureFlags,
                payloads: featureFlagDetails.featureFlagPayloads,
                requestId: featureFlagDetails.requestId
            };
        }
        async getFeatureFlagDetailsStateless(distinctId) {
            let groups = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : {}, personProperties = arguments.length > 2 && void 0 !== arguments[2] ? arguments[2] : {}, groupProperties = arguments.length > 3 && void 0 !== arguments[3] ? arguments[3] : {}, disableGeoip = arguments.length > 4 ? arguments[4] : void 0, flagKeysToEvaluate = arguments.length > 5 ? arguments[5] : void 0;
            var _flagsResponse_quotaLimited;
            await this._initPromise;
            const extraPayload = {};
            if (null != disableGeoip ? disableGeoip : this.disableGeoip) extraPayload['geoip_disable'] = true;
            if (flagKeysToEvaluate) extraPayload['flag_keys_to_evaluate'] = flagKeysToEvaluate;
            const flagsResponse = await this.getFlags(distinctId, groups, personProperties, groupProperties, extraPayload);
            if (void 0 === flagsResponse) return;
            if (flagsResponse.errorsWhileComputingFlags) console.error('[FEATURE FLAGS] Error while computing feature flags, some flags may be missing or incorrect. Learn more at https://posthog.com/docs/feature-flags/best-practices');
            if (null == (_flagsResponse_quotaLimited = flagsResponse.quotaLimited) ? void 0 : _flagsResponse_quotaLimited.includes("feature_flags")) {
                console.warn('[FEATURE FLAGS] Feature flags quota limit exceeded - feature flags unavailable. Learn more about billing limits at https://posthog.com/docs/billing/limits-alerts');
                return {
                    flags: {},
                    featureFlags: {},
                    featureFlagPayloads: {},
                    requestId: null == flagsResponse ? void 0 : flagsResponse.requestId
                };
            }
            return flagsResponse;
        }
        async getSurveysStateless() {
            await this._initPromise;
            if (true === this.disableSurveys) {
                this.logMsgIfDebug(()=>console.log('PostHog Debug', 'Loading surveys is disabled.'));
                return [];
            }
            const url = `${this.host}/api/surveys/?token=${this.apiKey}`;
            const fetchOptions = {
                method: 'GET',
                headers: {
                    ...this.getCustomHeaders(),
                    'Content-Type': 'application/json'
                }
            };
            const response = await this.fetchWithRetry(url, fetchOptions).then((response)=>{
                if (200 !== response.status || !response.json) {
                    const msg = `Surveys API could not be loaded: ${response.status}`;
                    const error = new Error(msg);
                    this.logMsgIfDebug(()=>console.error(error));
                    this._events.emit('error', new Error(msg));
                    return;
                }
                return response.json();
            }).catch((error)=>{
                this.logMsgIfDebug(()=>console.error('Surveys API could not be loaded', error));
                this._events.emit('error', error);
            });
            const newSurveys = null == response ? void 0 : response.surveys;
            if (newSurveys) this.logMsgIfDebug(()=>console.log('PostHog Debug', 'Surveys fetched from API: ', JSON.stringify(newSurveys)));
            return null != newSurveys ? newSurveys : [];
        }
        get props() {
            if (!this._props) this._props = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.Props);
            return this._props || {};
        }
        set props(val) {
            this._props = val;
        }
        async register(properties) {
            this.wrap(()=>{
                this.props = {
                    ...this.props,
                    ...properties
                };
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.Props, this.props);
            });
        }
        async unregister(property) {
            this.wrap(()=>{
                delete this.props[property];
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.Props, this.props);
            });
        }
        enqueue(type, _message, options) {
            this.wrap(()=>{
                if (this.optedOut) return void this._events.emit(type, "Library is disabled. Not sending event. To re-enable, call posthog.optIn()");
                const message = this.prepareMessage(type, _message, options);
                const queue = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.Queue) || [];
                if (queue.length >= this.maxQueueSize) {
                    queue.shift();
                    this.logMsgIfDebug(()=>console.info('Queue is full, the oldest event is dropped.'));
                }
                queue.push({
                    message
                });
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.Queue, queue);
                this._events.emit(type, message);
                if (queue.length >= this.flushAt) this.flushBackground();
                if (this.flushInterval && !this._flushTimer) this._flushTimer = (0, _utils__WEBPACK_IMPORTED_MODULE_2__.safeSetTimeout)(()=>this.flushBackground(), this.flushInterval);
            });
        }
        async sendImmediate(type, _message, options) {
            if (this.disabled) return void this.logMsgIfDebug(()=>console.warn('[PostHog] The client is disabled'));
            if (!this._isInitialized) await this._initPromise;
            if (this.optedOut) return void this._events.emit(type, "Library is disabled. Not sending event. To re-enable, call posthog.optIn()");
            const data = {
                api_key: this.apiKey,
                batch: [
                    this.prepareMessage(type, _message, options)
                ],
                sent_at: (0, _utils__WEBPACK_IMPORTED_MODULE_2__.currentISOTime)()
            };
            if (this.historicalMigration) data.historical_migration = true;
            const payload = JSON.stringify(data);
            const url = `${this.host}/batch/`;
            const gzippedPayload = this.disableCompression ? null : await (0, _gzip__WEBPACK_IMPORTED_MODULE_3__.gzipCompress)(payload, this.isDebug);
            const fetchOptions = {
                method: 'POST',
                headers: {
                    ...this.getCustomHeaders(),
                    'Content-Type': 'application/json',
                    ...null !== gzippedPayload && {
                        'Content-Encoding': 'gzip'
                    }
                },
                body: gzippedPayload || payload
            };
            try {
                await this.fetchWithRetry(url, fetchOptions);
            } catch (err) {
                this._events.emit('error', err);
            }
        }
        prepareMessage(type, _message, options) {
            const message = {
                ..._message,
                type: type,
                library: this.getLibraryId(),
                library_version: this.getLibraryVersion(),
                timestamp: (null == options ? void 0 : options.timestamp) ? null == options ? void 0 : options.timestamp : (0, _utils__WEBPACK_IMPORTED_MODULE_2__.currentISOTime)(),
                uuid: (null == options ? void 0 : options.uuid) ? options.uuid : (0, _vendor_uuidv7__WEBPACK_IMPORTED_MODULE_5__.uuidv7)()
            };
            var _options_disableGeoip;
            const addGeoipDisableProperty = null != (_options_disableGeoip = null == options ? void 0 : options.disableGeoip) ? _options_disableGeoip : this.disableGeoip;
            if (addGeoipDisableProperty) {
                if (!message.properties) message.properties = {};
                message['properties']['$geoip_disable'] = true;
            }
            if (message.distinctId) {
                message.distinct_id = message.distinctId;
                delete message.distinctId;
            }
            return message;
        }
        clearFlushTimer() {
            if (this._flushTimer) {
                clearTimeout(this._flushTimer);
                this._flushTimer = void 0;
            }
        }
        flushBackground() {
            this.flush().catch(async (err)=>{
                await logFlushError(err);
            });
        }
        async flush() {
            const nextFlushPromise = (0, _utils__WEBPACK_IMPORTED_MODULE_2__.allSettled)([
                this.flushPromise
            ]).then(()=>this._flush());
            this.flushPromise = nextFlushPromise;
            this.addPendingPromise(nextFlushPromise);
            (0, _utils__WEBPACK_IMPORTED_MODULE_2__.allSettled)([
                nextFlushPromise
            ]).then(()=>{
                if (this.flushPromise === nextFlushPromise) this.flushPromise = null;
            });
            return nextFlushPromise;
        }
        getCustomHeaders() {
            const customUserAgent = this.getCustomUserAgent();
            const headers = {};
            if (customUserAgent && '' !== customUserAgent) headers['User-Agent'] = customUserAgent;
            return headers;
        }
        async _flush() {
            this.clearFlushTimer();
            await this._initPromise;
            let queue = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.Queue) || [];
            if (!queue.length) return;
            const sentMessages = [];
            const originalQueueLength = queue.length;
            while(queue.length > 0 && sentMessages.length < originalQueueLength){
                const batchItems = queue.slice(0, this.maxBatchSize);
                const batchMessages = batchItems.map((item)=>item.message);
                const persistQueueChange = ()=>{
                    const refreshedQueue = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.Queue) || [];
                    const newQueue = refreshedQueue.slice(batchItems.length);
                    this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.Queue, newQueue);
                    queue = newQueue;
                };
                const data = {
                    api_key: this.apiKey,
                    batch: batchMessages,
                    sent_at: (0, _utils__WEBPACK_IMPORTED_MODULE_2__.currentISOTime)()
                };
                if (this.historicalMigration) data.historical_migration = true;
                const payload = JSON.stringify(data);
                const url = `${this.host}/batch/`;
                const gzippedPayload = this.disableCompression ? null : await (0, _gzip__WEBPACK_IMPORTED_MODULE_3__.gzipCompress)(payload, this.isDebug);
                const fetchOptions = {
                    method: 'POST',
                    headers: {
                        ...this.getCustomHeaders(),
                        'Content-Type': 'application/json',
                        ...null !== gzippedPayload && {
                            'Content-Encoding': 'gzip'
                        }
                    },
                    body: gzippedPayload || payload
                };
                const retryOptions = {
                    retryCheck: (err)=>{
                        if (isPostHogFetchContentTooLargeError(err)) return false;
                        return isPostHogFetchError(err);
                    }
                };
                try {
                    await this.fetchWithRetry(url, fetchOptions, retryOptions);
                } catch (err) {
                    if (isPostHogFetchContentTooLargeError(err) && batchMessages.length > 1) {
                        this.maxBatchSize = Math.max(1, Math.floor(batchMessages.length / 2));
                        this.logMsgIfDebug(()=>console.warn(`Received 413 when sending batch of size ${batchMessages.length}, reducing batch size to ${this.maxBatchSize}`));
                        continue;
                    }
                    if (!(err instanceof PostHogFetchNetworkError)) persistQueueChange();
                    this._events.emit('error', err);
                    throw err;
                }
                persistQueueChange();
                sentMessages.push(...batchMessages);
            }
            this._events.emit('flush', sentMessages);
        }
        async fetchWithRetry(url, options, retryOptions, requestTimeout) {
            var _AbortSignal;
            null != (_AbortSignal = AbortSignal).timeout || (_AbortSignal.timeout = function(ms) {
                const ctrl = new AbortController();
                setTimeout(()=>ctrl.abort(), ms);
                return ctrl.signal;
            });
            const body = options.body ? options.body : '';
            let reqByteLength = -1;
            try {
                reqByteLength = body instanceof Blob ? body.size : Buffer.byteLength(body, _utils__WEBPACK_IMPORTED_MODULE_2__.STRING_FORMAT);
            } catch (e) {
                if (body instanceof Blob) reqByteLength = body.size;
                else {
                    const encoded = new TextEncoder().encode(body);
                    reqByteLength = encoded.length;
                }
            }
            return await (0, _utils__WEBPACK_IMPORTED_MODULE_2__.retriable)(async ()=>{
                let res = null;
                try {
                    res = await this.fetch(url, {
                        signal: AbortSignal.timeout(null != requestTimeout ? requestTimeout : this.requestTimeout),
                        ...options
                    });
                } catch (e) {
                    throw new PostHogFetchNetworkError(e);
                }
                const isNoCors = 'no-cors' === options.mode;
                if (!isNoCors && (res.status < 200 || res.status >= 400)) throw new PostHogFetchHttpError(res, reqByteLength);
                return res;
            }, {
                ...this._retryOptions,
                ...retryOptions
            });
        }
        async _shutdown() {
            let shutdownTimeoutMs = arguments.length > 0 && void 0 !== arguments[0] ? arguments[0] : 30000;
            await this._initPromise;
            let hasTimedOut = false;
            this.clearFlushTimer();
            const doShutdown = async ()=>{
                try {
                    await Promise.all(Object.values(this.pendingPromises));
                    while(true){
                        const queue = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.Queue) || [];
                        if (0 === queue.length) break;
                        await this.flush();
                        if (hasTimedOut) break;
                    }
                } catch (e) {
                    if (!isPostHogFetchError(e)) throw e;
                    await logFlushError(e);
                }
            };
            return Promise.race([
                new Promise((_, reject)=>{
                    (0, _utils__WEBPACK_IMPORTED_MODULE_2__.safeSetTimeout)(()=>{
                        this.logMsgIfDebug(()=>console.error('Timed out while shutting down PostHog'));
                        hasTimedOut = true;
                        reject('Timeout while shutting down PostHog. Some events may not have been sent.');
                    }, shutdownTimeoutMs);
                }),
                doShutdown()
            ]);
        }
        async shutdown() {
            let shutdownTimeoutMs = arguments.length > 0 && void 0 !== arguments[0] ? arguments[0] : 30000;
            if (this.shutdownPromise) this.logMsgIfDebug(()=>console.warn('shutdown() called while already shutting down. shutdown() is meant to be called once before process exit - use flush() for per-request cleanup'));
            else this.shutdownPromise = this._shutdown(shutdownTimeoutMs).finally(()=>{
                this.shutdownPromise = null;
            });
            return this.shutdownPromise;
        }
        constructor(apiKey, options){
            this.flushPromise = null;
            this.shutdownPromise = null;
            this.pendingPromises = {};
            this._events = new _eventemitter__WEBPACK_IMPORTED_MODULE_4__.SimpleEventEmitter();
            this._isInitialized = false;
            (0, _utils__WEBPACK_IMPORTED_MODULE_2__.assert)(apiKey, "You must pass your PostHog project's api key.");
            this.apiKey = apiKey;
            this.host = (0, _utils__WEBPACK_IMPORTED_MODULE_2__.removeTrailingSlash)((null == options ? void 0 : options.host) || 'https://us.i.posthog.com');
            this.flushAt = (null == options ? void 0 : options.flushAt) ? Math.max(null == options ? void 0 : options.flushAt, 1) : 20;
            var _options_maxBatchSize;
            this.maxBatchSize = Math.max(this.flushAt, null != (_options_maxBatchSize = null == options ? void 0 : options.maxBatchSize) ? _options_maxBatchSize : 100);
            var _options_maxQueueSize;
            this.maxQueueSize = Math.max(this.flushAt, null != (_options_maxQueueSize = null == options ? void 0 : options.maxQueueSize) ? _options_maxQueueSize : 1000);
            var _options_flushInterval;
            this.flushInterval = null != (_options_flushInterval = null == options ? void 0 : options.flushInterval) ? _options_flushInterval : 10000;
            var _options_preloadFeatureFlags;
            this.preloadFeatureFlags = null != (_options_preloadFeatureFlags = null == options ? void 0 : options.preloadFeatureFlags) ? _options_preloadFeatureFlags : true;
            var _options_defaultOptIn;
            this.defaultOptIn = null != (_options_defaultOptIn = null == options ? void 0 : options.defaultOptIn) ? _options_defaultOptIn : true;
            var _options_disableSurveys;
            this.disableSurveys = null != (_options_disableSurveys = null == options ? void 0 : options.disableSurveys) ? _options_disableSurveys : false;
            var _options_fetchRetryCount, _options_fetchRetryDelay;
            this._retryOptions = {
                retryCount: null != (_options_fetchRetryCount = null == options ? void 0 : options.fetchRetryCount) ? _options_fetchRetryCount : 3,
                retryDelay: null != (_options_fetchRetryDelay = null == options ? void 0 : options.fetchRetryDelay) ? _options_fetchRetryDelay : 3000,
                retryCheck: isPostHogFetchError
            };
            var _options_requestTimeout;
            this.requestTimeout = null != (_options_requestTimeout = null == options ? void 0 : options.requestTimeout) ? _options_requestTimeout : 10000;
            var _options_featureFlagsRequestTimeoutMs;
            this.featureFlagsRequestTimeoutMs = null != (_options_featureFlagsRequestTimeoutMs = null == options ? void 0 : options.featureFlagsRequestTimeoutMs) ? _options_featureFlagsRequestTimeoutMs : 3000;
            var _options_remoteConfigRequestTimeoutMs;
            this.remoteConfigRequestTimeoutMs = null != (_options_remoteConfigRequestTimeoutMs = null == options ? void 0 : options.remoteConfigRequestTimeoutMs) ? _options_remoteConfigRequestTimeoutMs : 3000;
            var _options_disableGeoip;
            this.disableGeoip = null != (_options_disableGeoip = null == options ? void 0 : options.disableGeoip) ? _options_disableGeoip : true;
            var _options_disabled;
            this.disabled = null != (_options_disabled = null == options ? void 0 : options.disabled) ? _options_disabled : false;
            var _options_historicalMigration;
            this.historicalMigration = null != (_options_historicalMigration = null == options ? void 0 : options.historicalMigration) ? _options_historicalMigration : false;
            this._initPromise = Promise.resolve();
            this._isInitialized = true;
            var _options_disableCompression;
            this.disableCompression = !(0, _gzip__WEBPACK_IMPORTED_MODULE_3__.isGzipSupported)() || (null != (_options_disableCompression = null == options ? void 0 : options.disableCompression) ? _options_disableCompression : false);
        }
    }
    class PostHogCore extends PostHogCoreStateless {
        setupBootstrap(options) {
            const bootstrap = null == options ? void 0 : options.bootstrap;
            if (!bootstrap) return;
            if (bootstrap.distinctId) if (bootstrap.isIdentifiedId) {
                const distinctId = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.DistinctId);
                if (!distinctId) this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.DistinctId, bootstrap.distinctId);
            } else {
                const anonymousId = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.AnonymousId);
                if (!anonymousId) this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.AnonymousId, bootstrap.distinctId);
            }
            const bootstrapFeatureFlags = bootstrap.featureFlags;
            var _bootstrap_featureFlagPayloads;
            const bootstrapFeatureFlagPayloads = null != (_bootstrap_featureFlagPayloads = bootstrap.featureFlagPayloads) ? _bootstrap_featureFlagPayloads : {};
            if (bootstrapFeatureFlags && Object.keys(bootstrapFeatureFlags).length) {
                const normalizedBootstrapFeatureFlagDetails = (0, _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.createFlagsResponseFromFlagsAndPayloads)(bootstrapFeatureFlags, bootstrapFeatureFlagPayloads);
                if (Object.keys(normalizedBootstrapFeatureFlagDetails.flags).length > 0) {
                    this.setBootstrappedFeatureFlagDetails(normalizedBootstrapFeatureFlagDetails);
                    const currentFeatureFlagDetails = this.getKnownFeatureFlagDetails() || {
                        flags: {},
                        requestId: void 0
                    };
                    const newFeatureFlagDetails = {
                        flags: {
                            ...normalizedBootstrapFeatureFlagDetails.flags,
                            ...currentFeatureFlagDetails.flags
                        },
                        requestId: normalizedBootstrapFeatureFlagDetails.requestId
                    };
                    this.setKnownFeatureFlagDetails(newFeatureFlagDetails);
                }
            }
        }
        clearProps() {
            this.props = void 0;
            this.sessionProps = {};
            this.flagCallReported = {};
        }
        on(event, cb) {
            return this._events.on(event, cb);
        }
        reset(propertiesToKeep) {
            this.wrap(()=>{
                const allPropertiesToKeep = [
                    _types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.Queue,
                    ...propertiesToKeep || []
                ];
                this.clearProps();
                for (const key of Object.keys(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty))if (!allPropertiesToKeep.includes(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty[key])) this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty[key], null);
                this.reloadFeatureFlags();
            });
        }
        getCommonEventProperties() {
            const featureFlags = this.getFeatureFlags();
            const featureVariantProperties = {};
            if (featureFlags) for (const [feature, variant] of Object.entries(featureFlags))featureVariantProperties[`$feature/${feature}`] = variant;
            return {
                ...maybeAdd('$active_feature_flags', featureFlags ? Object.keys(featureFlags) : void 0),
                ...featureVariantProperties,
                ...super.getCommonEventProperties()
            };
        }
        enrichProperties(properties) {
            return {
                ...this.props,
                ...this.sessionProps,
                ...properties || {},
                ...this.getCommonEventProperties(),
                $session_id: this.getSessionId()
            };
        }
        getSessionId() {
            if (!this._isInitialized) return '';
            let sessionId = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.SessionId);
            const sessionLastTimestamp = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.SessionLastTimestamp) || 0;
            const sessionStartTimestamp = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.SessionStartTimestamp) || 0;
            const now = Date.now();
            const sessionLastDif = now - sessionLastTimestamp;
            const sessionStartDif = now - sessionStartTimestamp;
            if (!sessionId || sessionLastDif > 1000 * this._sessionExpirationTimeSeconds || sessionStartDif > 1000 * this._sessionMaxLengthSeconds) {
                sessionId = (0, _vendor_uuidv7__WEBPACK_IMPORTED_MODULE_5__.uuidv7)();
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.SessionId, sessionId);
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.SessionStartTimestamp, now);
            }
            this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.SessionLastTimestamp, now);
            return sessionId;
        }
        resetSessionId() {
            this.wrap(()=>{
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.SessionId, null);
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.SessionLastTimestamp, null);
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.SessionStartTimestamp, null);
            });
        }
        getAnonymousId() {
            if (!this._isInitialized) return '';
            let anonId = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.AnonymousId);
            if (!anonId) {
                anonId = (0, _vendor_uuidv7__WEBPACK_IMPORTED_MODULE_5__.uuidv7)();
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.AnonymousId, anonId);
            }
            return anonId;
        }
        getDistinctId() {
            if (!this._isInitialized) return '';
            return this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.DistinctId) || this.getAnonymousId();
        }
        registerForSession(properties) {
            this.sessionProps = {
                ...this.sessionProps,
                ...properties
            };
        }
        unregisterForSession(property) {
            delete this.sessionProps[property];
        }
        identify(distinctId, properties, options) {
            this.wrap(()=>{
                const previousDistinctId = this.getDistinctId();
                distinctId = distinctId || previousDistinctId;
                if (null == properties ? void 0 : properties.$groups) this.groups(properties.$groups);
                const userPropsOnce = null == properties ? void 0 : properties.$set_once;
                null == properties || delete properties.$set_once;
                const userProps = (null == properties ? void 0 : properties.$set) || properties;
                const allProperties = this.enrichProperties({
                    $anon_distinct_id: this.getAnonymousId(),
                    ...maybeAdd('$set', userProps),
                    ...maybeAdd('$set_once', userPropsOnce)
                });
                if (distinctId !== previousDistinctId) {
                    this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.AnonymousId, previousDistinctId);
                    this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.DistinctId, distinctId);
                    this.reloadFeatureFlags();
                }
                super.identifyStateless(distinctId, allProperties, options);
            });
        }
        capture(event, properties, options) {
            this.wrap(()=>{
                const distinctId = this.getDistinctId();
                if (null == properties ? void 0 : properties.$groups) this.groups(properties.$groups);
                const allProperties = this.enrichProperties(properties);
                super.captureStateless(distinctId, event, allProperties, options);
            });
        }
        alias(alias) {
            this.wrap(()=>{
                const distinctId = this.getDistinctId();
                const allProperties = this.enrichProperties({});
                super.aliasStateless(alias, distinctId, allProperties);
            });
        }
        autocapture(eventType, elements) {
            let properties = arguments.length > 2 && void 0 !== arguments[2] ? arguments[2] : {}, options = arguments.length > 3 ? arguments[3] : void 0;
            this.wrap(()=>{
                const distinctId = this.getDistinctId();
                const payload = {
                    distinct_id: distinctId,
                    event: '$autocapture',
                    properties: {
                        ...this.enrichProperties(properties),
                        $event_type: eventType,
                        $elements: elements
                    }
                };
                this.enqueue('autocapture', payload, options);
            });
        }
        groups(groups) {
            this.wrap(()=>{
                const existingGroups = this.props.$groups || {};
                this.register({
                    $groups: {
                        ...existingGroups,
                        ...groups
                    }
                });
                if (Object.keys(groups).find((type)=>existingGroups[type] !== groups[type])) this.reloadFeatureFlags();
            });
        }
        group(groupType, groupKey, groupProperties, options) {
            this.wrap(()=>{
                this.groups({
                    [groupType]: groupKey
                });
                if (groupProperties) this.groupIdentify(groupType, groupKey, groupProperties, options);
            });
        }
        groupIdentify(groupType, groupKey, groupProperties, options) {
            this.wrap(()=>{
                const distinctId = this.getDistinctId();
                const eventProperties = this.enrichProperties({});
                super.groupIdentifyStateless(groupType, groupKey, groupProperties, options, distinctId, eventProperties);
            });
        }
        setPersonPropertiesForFlags(properties) {
            this.wrap(()=>{
                const existingProperties = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.PersonProperties) || {};
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.PersonProperties, {
                    ...existingProperties,
                    ...properties
                });
            });
        }
        resetPersonPropertiesForFlags() {
            this.wrap(()=>{
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.PersonProperties, null);
            });
        }
        setGroupPropertiesForFlags(properties) {
            this.wrap(()=>{
                const existingProperties = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.GroupProperties) || {};
                if (0 !== Object.keys(existingProperties).length) Object.keys(existingProperties).forEach((groupType)=>{
                    existingProperties[groupType] = {
                        ...existingProperties[groupType],
                        ...properties[groupType]
                    };
                    delete properties[groupType];
                });
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.GroupProperties, {
                    ...existingProperties,
                    ...properties
                });
            });
        }
        resetGroupPropertiesForFlags() {
            this.wrap(()=>{
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.GroupProperties, null);
            });
        }
        async remoteConfigAsync() {
            await this._initPromise;
            if (this._remoteConfigResponsePromise) return this._remoteConfigResponsePromise;
            return this._remoteConfigAsync();
        }
        async flagsAsync() {
            let sendAnonDistinctId = arguments.length > 0 && void 0 !== arguments[0] ? arguments[0] : true;
            await this._initPromise;
            if (this._flagsResponsePromise) return this._flagsResponsePromise;
            return this._flagsAsync(sendAnonDistinctId);
        }
        cacheSessionReplay(source, response) {
            const sessionReplay = null == response ? void 0 : response.sessionRecording;
            if (sessionReplay) {
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.SessionReplay, sessionReplay);
                this.logMsgIfDebug(()=>console.log('PostHog Debug', `Session replay config from ${source}: `, JSON.stringify(sessionReplay)));
            } else if ('boolean' == typeof sessionReplay && false === sessionReplay) {
                this.logMsgIfDebug(()=>console.info('PostHog Debug', `Session replay config from ${source} disabled.`));
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.SessionReplay, null);
            }
        }
        async _remoteConfigAsync() {
            this._remoteConfigResponsePromise = this._initPromise.then(()=>{
                let remoteConfig = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.RemoteConfig);
                this.logMsgIfDebug(()=>console.log('PostHog Debug', 'Cached remote config: ', JSON.stringify(remoteConfig)));
                return super.getRemoteConfig().then((response)=>{
                    if (response) {
                        var _response_supportedCompression;
                        const remoteConfigWithoutSurveys = {
                            ...response
                        };
                        delete remoteConfigWithoutSurveys.surveys;
                        this.logMsgIfDebug(()=>console.log('PostHog Debug', 'Fetched remote config: ', JSON.stringify(remoteConfigWithoutSurveys)));
                        if (false === this.disableSurveys) {
                            const surveys = response.surveys;
                            let hasSurveys = true;
                            if (Array.isArray(surveys)) this.logMsgIfDebug(()=>console.log('PostHog Debug', 'Surveys fetched from remote config: ', JSON.stringify(surveys)));
                            else {
                                this.logMsgIfDebug(()=>console.log('PostHog Debug', 'There are no surveys.'));
                                hasSurveys = false;
                            }
                            if (hasSurveys) this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.Surveys, surveys);
                            else this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.Surveys, null);
                        } else this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.Surveys, null);
                        this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.RemoteConfig, remoteConfigWithoutSurveys);
                        this.cacheSessionReplay('remote config', response);
                        if (false === response.hasFeatureFlags) {
                            this.setKnownFeatureFlagDetails({
                                flags: {}
                            });
                            this.logMsgIfDebug(()=>console.warn('Remote config has no feature flags, will not load feature flags.'));
                        } else if (false !== this.preloadFeatureFlags) this.reloadFeatureFlags();
                        if (!(null == (_response_supportedCompression = response.supportedCompression) ? void 0 : _response_supportedCompression.includes(_types__WEBPACK_IMPORTED_MODULE_0__.Compression.GZipJS))) this.disableCompression = true;
                        remoteConfig = response;
                    }
                    return remoteConfig;
                });
            }).finally(()=>{
                this._remoteConfigResponsePromise = void 0;
            });
            return this._remoteConfigResponsePromise;
        }
        async _flagsAsync() {
            let sendAnonDistinctId = arguments.length > 0 && void 0 !== arguments[0] ? arguments[0] : true;
            this._flagsResponsePromise = this._initPromise.then(async ()=>{
                var _res_quotaLimited;
                const distinctId = this.getDistinctId();
                const groups = this.props.$groups || {};
                const personProperties = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.PersonProperties) || {};
                const groupProperties = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.GroupProperties) || {};
                const extraProperties = {
                    $anon_distinct_id: sendAnonDistinctId ? this.getAnonymousId() : void 0
                };
                const res = await super.getFlags(distinctId, groups, personProperties, groupProperties, extraProperties);
                if (null == res ? void 0 : null == (_res_quotaLimited = res.quotaLimited) ? void 0 : _res_quotaLimited.includes("feature_flags")) {
                    this.setKnownFeatureFlagDetails(null);
                    console.warn('[FEATURE FLAGS] Feature flags quota limit exceeded - unsetting all flags. Learn more about billing limits at https://posthog.com/docs/billing/limits-alerts');
                    return res;
                }
                if (null == res ? void 0 : res.featureFlags) {
                    if (this.sendFeatureFlagEvent) this.flagCallReported = {};
                    let newFeatureFlagDetails = res;
                    if (res.errorsWhileComputingFlags) {
                        const currentFlagDetails = this.getKnownFeatureFlagDetails();
                        this.logMsgIfDebug(()=>console.log('PostHog Debug', 'Cached feature flags: ', JSON.stringify(currentFlagDetails)));
                        newFeatureFlagDetails = {
                            ...res,
                            flags: {
                                ...null == currentFlagDetails ? void 0 : currentFlagDetails.flags,
                                ...res.flags
                            }
                        };
                    }
                    this.setKnownFeatureFlagDetails(newFeatureFlagDetails);
                    this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.FlagsEndpointWasHit, true);
                    this.cacheSessionReplay('flags', res);
                }
                return res;
            }).finally(()=>{
                this._flagsResponsePromise = void 0;
            });
            return this._flagsResponsePromise;
        }
        setKnownFeatureFlagDetails(flagsResponse) {
            this.wrap(()=>{
                this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.FeatureFlagDetails, flagsResponse);
                var _flagsResponse_flags;
                this._events.emit('featureflags', (0, _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.getFlagValuesFromFlags)(null != (_flagsResponse_flags = null == flagsResponse ? void 0 : flagsResponse.flags) ? _flagsResponse_flags : {}));
            });
        }
        getKnownFeatureFlagDetails() {
            const storedDetails = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.FeatureFlagDetails);
            if (!storedDetails) {
                const featureFlags = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.FeatureFlags);
                const featureFlagPayloads = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.FeatureFlagPayloads);
                if (void 0 === featureFlags && void 0 === featureFlagPayloads) return;
                return (0, _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.createFlagsResponseFromFlagsAndPayloads)(null != featureFlags ? featureFlags : {}, null != featureFlagPayloads ? featureFlagPayloads : {});
            }
            return (0, _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.normalizeFlagsResponse)(storedDetails);
        }
        getKnownFeatureFlags() {
            const featureFlagDetails = this.getKnownFeatureFlagDetails();
            if (!featureFlagDetails) return;
            return (0, _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.getFlagValuesFromFlags)(featureFlagDetails.flags);
        }
        getKnownFeatureFlagPayloads() {
            const featureFlagDetails = this.getKnownFeatureFlagDetails();
            if (!featureFlagDetails) return;
            return (0, _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.getPayloadsFromFlags)(featureFlagDetails.flags);
        }
        getBootstrappedFeatureFlagDetails() {
            const details = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.BootstrapFeatureFlagDetails);
            if (!details) return;
            return details;
        }
        setBootstrappedFeatureFlagDetails(details) {
            this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.BootstrapFeatureFlagDetails, details);
        }
        getBootstrappedFeatureFlags() {
            const details = this.getBootstrappedFeatureFlagDetails();
            if (!details) return;
            return (0, _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.getFlagValuesFromFlags)(details.flags);
        }
        getBootstrappedFeatureFlagPayloads() {
            const details = this.getBootstrappedFeatureFlagDetails();
            if (!details) return;
            return (0, _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.getPayloadsFromFlags)(details.flags);
        }
        getFeatureFlag(key) {
            const details = this.getFeatureFlagDetails();
            if (!details) return;
            const featureFlag = details.flags[key];
            let response = (0, _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.getFeatureFlagValue)(featureFlag);
            if (void 0 === response) response = false;
            if (this.sendFeatureFlagEvent && !this.flagCallReported[key]) {
                var _this_getBootstrappedFeatureFlags, _this_getBootstrappedFeatureFlagPayloads, _featureFlag_metadata, _featureFlag_metadata1, _featureFlag_reason, _featureFlag_reason1;
                const bootstrappedResponse = null == (_this_getBootstrappedFeatureFlags = this.getBootstrappedFeatureFlags()) ? void 0 : _this_getBootstrappedFeatureFlags[key];
                const bootstrappedPayload = null == (_this_getBootstrappedFeatureFlagPayloads = this.getBootstrappedFeatureFlagPayloads()) ? void 0 : _this_getBootstrappedFeatureFlagPayloads[key];
                this.flagCallReported[key] = true;
                var _featureFlag_reason_description;
                this.capture('$feature_flag_called', {
                    $feature_flag: key,
                    $feature_flag_response: response,
                    ...maybeAdd('$feature_flag_id', null == featureFlag ? void 0 : null == (_featureFlag_metadata = featureFlag.metadata) ? void 0 : _featureFlag_metadata.id),
                    ...maybeAdd('$feature_flag_version', null == featureFlag ? void 0 : null == (_featureFlag_metadata1 = featureFlag.metadata) ? void 0 : _featureFlag_metadata1.version),
                    ...maybeAdd('$feature_flag_reason', null != (_featureFlag_reason_description = null == featureFlag ? void 0 : null == (_featureFlag_reason = featureFlag.reason) ? void 0 : _featureFlag_reason.description) ? _featureFlag_reason_description : null == featureFlag ? void 0 : null == (_featureFlag_reason1 = featureFlag.reason) ? void 0 : _featureFlag_reason1.code),
                    ...maybeAdd('$feature_flag_bootstrapped_response', bootstrappedResponse),
                    ...maybeAdd('$feature_flag_bootstrapped_payload', bootstrappedPayload),
                    $used_bootstrap_value: !this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.FlagsEndpointWasHit),
                    ...maybeAdd('$feature_flag_request_id', details.requestId)
                });
            }
            return response;
        }
        getFeatureFlagPayload(key) {
            const payloads = this.getFeatureFlagPayloads();
            if (!payloads) return;
            const response = payloads[key];
            if (void 0 === response) return null;
            return response;
        }
        getFeatureFlagPayloads() {
            var _this_getFeatureFlagDetails;
            return null == (_this_getFeatureFlagDetails = this.getFeatureFlagDetails()) ? void 0 : _this_getFeatureFlagDetails.featureFlagPayloads;
        }
        getFeatureFlags() {
            var _this_getFeatureFlagDetails;
            return null == (_this_getFeatureFlagDetails = this.getFeatureFlagDetails()) ? void 0 : _this_getFeatureFlagDetails.featureFlags;
        }
        getFeatureFlagDetails() {
            let details = this.getKnownFeatureFlagDetails();
            const overriddenFlags = this.getPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.OverrideFeatureFlags);
            if (!overriddenFlags) return details;
            details = null != details ? details : {
                featureFlags: {},
                featureFlagPayloads: {},
                flags: {}
            };
            var _details_flags;
            const flags = null != (_details_flags = details.flags) ? _details_flags : {};
            for(const key in overriddenFlags)if (overriddenFlags[key]) flags[key] = (0, _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.updateFlagValue)(flags[key], overriddenFlags[key]);
            else delete flags[key];
            const result = {
                ...details,
                flags
            };
            return (0, _featureFlagUtils__WEBPACK_IMPORTED_MODULE_1__.normalizeFlagsResponse)(result);
        }
        getFeatureFlagsAndPayloads() {
            const flags = this.getFeatureFlags();
            const payloads = this.getFeatureFlagPayloads();
            return {
                flags,
                payloads
            };
        }
        isFeatureEnabled(key) {
            const response = this.getFeatureFlag(key);
            if (void 0 === response) return;
            return !!response;
        }
        reloadFeatureFlags(options) {
            this.flagsAsync(true).then((res)=>{
                var _options_cb;
                null == options || null == (_options_cb = options.cb) || _options_cb.call(options, void 0, null == res ? void 0 : res.featureFlags);
            }).catch((e)=>{
                var _options_cb;
                null == options || null == (_options_cb = options.cb) || _options_cb.call(options, e, void 0);
                if (!(null == options ? void 0 : options.cb)) this.logMsgIfDebug(()=>console.log('PostHog Debug', 'Error reloading feature flags', e));
            });
        }
        async reloadRemoteConfigAsync() {
            return await this.remoteConfigAsync();
        }
        async reloadFeatureFlagsAsync(sendAnonDistinctId) {
            var _this;
            return null == (_this = await this.flagsAsync(null != sendAnonDistinctId ? sendAnonDistinctId : true)) ? void 0 : _this.featureFlags;
        }
        onFeatureFlags(cb) {
            return this.on('featureflags', async ()=>{
                const flags = this.getFeatureFlags();
                if (flags) cb(flags);
            });
        }
        onFeatureFlag(key, cb) {
            return this.on('featureflags', async ()=>{
                const flagResponse = this.getFeatureFlag(key);
                if (void 0 !== flagResponse) cb(flagResponse);
            });
        }
        async overrideFeatureFlag(flags) {
            this.wrap(()=>{
                if (null === flags) return this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.OverrideFeatureFlags, null);
                return this.setPersistedProperty(_types__WEBPACK_IMPORTED_MODULE_0__.PostHogPersistedProperty.OverrideFeatureFlags, flags);
            });
        }
        captureException(error, additionalProperties) {
            const properties = {
                $exception_level: 'error',
                $exception_list: [
                    {
                        type: (0, _utils__WEBPACK_IMPORTED_MODULE_2__.isError)(error) ? error.name : 'Error',
                        value: (0, _utils__WEBPACK_IMPORTED_MODULE_2__.isError)(error) ? error.message : error,
                        mechanism: {
                            handled: true,
                            synthetic: false
                        }
                    }
                ],
                ...additionalProperties
            };
            properties.$exception_personURL = new URL(`/project/${this.apiKey}/person/${this.getDistinctId()}`, this.host).toString();
            this.capture('$exception', properties);
        }
        captureTraceFeedback(traceId, userFeedback) {
            this.capture('$ai_feedback', {
                $ai_feedback_text: userFeedback,
                $ai_trace_id: String(traceId)
            });
        }
        captureTraceMetric(traceId, metricName, metricValue) {
            this.capture('$ai_metric', {
                $ai_metric_name: metricName,
                $ai_metric_value: String(metricValue),
                $ai_trace_id: String(traceId)
            });
        }
        constructor(apiKey, options){
            var _options_disableGeoip;
            const disableGeoipOption = null != (_options_disableGeoip = null == options ? void 0 : options.disableGeoip) ? _options_disableGeoip : false;
            var _options_featureFlagsRequestTimeoutMs;
            const featureFlagsRequestTimeoutMs = null != (_options_featureFlagsRequestTimeoutMs = null == options ? void 0 : options.featureFlagsRequestTimeoutMs) ? _options_featureFlagsRequestTimeoutMs : 10000;
            super(apiKey, {
                ...options,
                disableGeoip: disableGeoipOption,
                featureFlagsRequestTimeoutMs
            }), this.flagCallReported = {}, this._sessionMaxLengthSeconds = 86400, this.sessionProps = {};
            var _options_sendFeatureFlagEvent;
            this.sendFeatureFlagEvent = null != (_options_sendFeatureFlagEvent = null == options ? void 0 : options.sendFeatureFlagEvent) ? _options_sendFeatureFlagEvent : true;
            var _options_sessionExpirationTimeSeconds;
            this._sessionExpirationTimeSeconds = null != (_options_sessionExpirationTimeSeconds = null == options ? void 0 : options.sessionExpirationTimeSeconds) ? _options_sessionExpirationTimeSeconds : 1800;
        }
    }
})();
exports.PostHogCore = __webpack_exports__.PostHogCore;
exports.PostHogCoreStateless = __webpack_exports__.PostHogCoreStateless;
exports.getFeatureFlagValue = __webpack_exports__.getFeatureFlagValue;
exports.logFlushError = __webpack_exports__.logFlushError;
exports.maybeAdd = __webpack_exports__.maybeAdd;
for(var __webpack_i__ in __webpack_exports__)if (-1 === [
    "PostHogCore",
    "PostHogCoreStateless",
    "getFeatureFlagValue",
    "logFlushError",
    "maybeAdd"
].indexOf(__webpack_i__)) exports[__webpack_i__] = __webpack_exports__[__webpack_i__];
Object.defineProperty(exports, '__esModule', {
    value: true
});
