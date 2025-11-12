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
export { createFlagsResponseFromFlagsAndPayloads, getFeatureFlagValue, getFlagDetailsFromFlagsAndPayloads, getFlagValuesFromFlags, getPayloadsFromFlags, normalizeFlagsResponse, parsePayload, updateFlagValue };
