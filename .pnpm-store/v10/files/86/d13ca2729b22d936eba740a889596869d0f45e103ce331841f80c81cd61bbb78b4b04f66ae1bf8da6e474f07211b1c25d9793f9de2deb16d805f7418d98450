"use strict";
var __webpack_require__ = {};
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
__webpack_require__.r(__webpack_exports__);
__webpack_require__.d(__webpack_exports__, {
    createFlagsResponseFromFlagsAndPayloads: ()=>createFlagsResponseFromFlagsAndPayloads,
    getFeatureFlagValue: ()=>getFeatureFlagValue,
    getFlagDetailsFromFlagsAndPayloads: ()=>getFlagDetailsFromFlagsAndPayloads,
    getFlagValuesFromFlags: ()=>getFlagValuesFromFlags,
    getPayloadsFromFlags: ()=>getPayloadsFromFlags,
    normalizeFlagsResponse: ()=>normalizeFlagsResponse,
    parsePayload: ()=>parsePayload,
    updateFlagValue: ()=>updateFlagValue
});
const normalizeFlagsResponse = (flagsResponse)=>{
    if ('flags' in flagsResponse) {
        const featureFlags = getFlagValuesFromFlags(flagsResponse.flags);
        const featureFlagPayloads = getPayloadsFromFlags(flagsResponse.flags);
        return {
            ...flagsResponse,
            featureFlags,
            featureFlagPayloads
        };
    }
    {
        var _flagsResponse_featureFlags;
        const featureFlags = null != (_flagsResponse_featureFlags = flagsResponse.featureFlags) ? _flagsResponse_featureFlags : {};
        const featureFlagPayloads = Object.fromEntries(Object.entries(flagsResponse.featureFlagPayloads || {}).map((param)=>{
            let [k, v] = param;
            return [
                k,
                parsePayload(v)
            ];
        }));
        const flags = Object.fromEntries(Object.entries(featureFlags).map((param)=>{
            let [key, value] = param;
            return [
                key,
                getFlagDetailFromFlagAndPayload(key, value, featureFlagPayloads[key])
            ];
        }));
        return {
            ...flagsResponse,
            featureFlags,
            featureFlagPayloads,
            flags
        };
    }
};
function getFlagDetailFromFlagAndPayload(key, value, payload) {
    return {
        key: key,
        enabled: 'string' == typeof value ? true : value,
        variant: 'string' == typeof value ? value : void 0,
        reason: void 0,
        metadata: {
            id: void 0,
            version: void 0,
            payload: payload ? JSON.stringify(payload) : void 0,
            description: void 0
        }
    };
}
const getFlagValuesFromFlags = (flags)=>Object.fromEntries(Object.entries(null != flags ? flags : {}).map((param)=>{
        let [key, detail] = param;
        return [
            key,
            getFeatureFlagValue(detail)
        ];
    }).filter((param)=>{
        let [, value] = param;
        return void 0 !== value;
    }));
const getPayloadsFromFlags = (flags)=>{
    const safeFlags = null != flags ? flags : {};
    return Object.fromEntries(Object.keys(safeFlags).filter((flag)=>{
        const details = safeFlags[flag];
        return details.enabled && details.metadata && void 0 !== details.metadata.payload;
    }).map((flag)=>{
        var _safeFlags_flag_metadata;
        const payload = null == (_safeFlags_flag_metadata = safeFlags[flag].metadata) ? void 0 : _safeFlags_flag_metadata.payload;
        return [
            flag,
            payload ? parsePayload(payload) : void 0
        ];
    }));
};
const getFlagDetailsFromFlagsAndPayloads = (flagsResponse)=>{
    var _flagsResponse_featureFlags;
    const flags = null != (_flagsResponse_featureFlags = flagsResponse.featureFlags) ? _flagsResponse_featureFlags : {};
    var _flagsResponse_featureFlagPayloads;
    const payloads = null != (_flagsResponse_featureFlagPayloads = flagsResponse.featureFlagPayloads) ? _flagsResponse_featureFlagPayloads : {};
    return Object.fromEntries(Object.entries(flags).map((param)=>{
        let [key, value] = param;
        return [
            key,
            {
                key: key,
                enabled: 'string' == typeof value ? true : value,
                variant: 'string' == typeof value ? value : void 0,
                reason: void 0,
                metadata: {
                    id: void 0,
                    version: void 0,
                    payload: (null == payloads ? void 0 : payloads[key]) ? JSON.stringify(payloads[key]) : void 0,
                    description: void 0
                }
            }
        ];
    }));
};
const getFeatureFlagValue = (detail)=>{
    var _detail_variant;
    return void 0 === detail ? void 0 : null != (_detail_variant = detail.variant) ? _detail_variant : detail.enabled;
};
const parsePayload = (response)=>{
    if ('string' != typeof response) return response;
    try {
        return JSON.parse(response);
    } catch (e) {
        return response;
    }
};
const createFlagsResponseFromFlagsAndPayloads = (featureFlags, featureFlagPayloads)=>{
    const allKeys = [
        ...new Set([
            ...Object.keys(null != featureFlags ? featureFlags : {}),
            ...Object.keys(null != featureFlagPayloads ? featureFlagPayloads : {})
        ])
    ];
    const enabledFlags = allKeys.filter((flag)=>!!featureFlags[flag] || !!featureFlagPayloads[flag]).reduce((res, key)=>{
        var _featureFlags_key;
        return res[key] = null != (_featureFlags_key = featureFlags[key]) ? _featureFlags_key : true, res;
    }, {});
    const flagDetails = {
        featureFlags: enabledFlags,
        featureFlagPayloads: null != featureFlagPayloads ? featureFlagPayloads : {}
    };
    return normalizeFlagsResponse(flagDetails);
};
const updateFlagValue = (flag, value)=>({
        ...flag,
        enabled: getEnabledFromValue(value),
        variant: getVariantFromValue(value)
    });
function getEnabledFromValue(value) {
    return 'string' == typeof value ? true : value;
}
function getVariantFromValue(value) {
    return 'string' == typeof value ? value : void 0;
}
exports.createFlagsResponseFromFlagsAndPayloads = __webpack_exports__.createFlagsResponseFromFlagsAndPayloads;
exports.getFeatureFlagValue = __webpack_exports__.getFeatureFlagValue;
exports.getFlagDetailsFromFlagsAndPayloads = __webpack_exports__.getFlagDetailsFromFlagsAndPayloads;
exports.getFlagValuesFromFlags = __webpack_exports__.getFlagValuesFromFlags;
exports.getPayloadsFromFlags = __webpack_exports__.getPayloadsFromFlags;
exports.normalizeFlagsResponse = __webpack_exports__.normalizeFlagsResponse;
exports.parsePayload = __webpack_exports__.parsePayload;
exports.updateFlagValue = __webpack_exports__.updateFlagValue;
for(var __webpack_i__ in __webpack_exports__)if (-1 === [
    "createFlagsResponseFromFlagsAndPayloads",
    "getFeatureFlagValue",
    "getFlagDetailsFromFlagsAndPayloads",
    "getFlagValuesFromFlags",
    "getPayloadsFromFlags",
    "normalizeFlagsResponse",
    "parsePayload",
    "updateFlagValue"
].indexOf(__webpack_i__)) exports[__webpack_i__] = __webpack_exports__[__webpack_i__];
Object.defineProperty(exports, '__esModule', {
    value: true
});
