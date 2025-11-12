"use strict";
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.COOKIE_CAMPAIGN_PARAMS = exports.MASKED = exports.EVENT_TO_PERSON_PROPERTIES = exports.CAMPAIGN_PARAMS = exports.PERSONAL_DATA_CAMPAIGN_PARAMS = void 0;
exports.getCampaignParams = getCampaignParams;
exports.getSearchInfo = getSearchInfo;
exports.getBrowserLanguage = getBrowserLanguage;
exports.getBrowserLanguagePrefix = getBrowserLanguagePrefix;
exports.getReferrer = getReferrer;
exports.getReferringDomain = getReferringDomain;
exports.getReferrerInfo = getReferrerInfo;
exports.getPersonInfo = getPersonInfo;
exports.getPersonPropsFromInfo = getPersonPropsFromInfo;
exports.getInitialPersonPropsFromInfo = getInitialPersonPropsFromInfo;
exports.getTimezone = getTimezone;
exports.getTimezoneOffset = getTimezoneOffset;
exports.getEventProperties = getEventProperties;
var request_utils_1 = require("./request-utils");
var core_1 = require("@posthog/core");
var config_1 = __importDefault(require("../config"));
var index_1 = require("./index");
var globals_1 = require("./globals");
var user_agent_utils_1 = require("./user-agent-utils");
var storage_1 = require("../storage");
var URL_REGEX_PREFIX = 'https?://(.*)';
// CAMPAIGN_PARAMS and EVENT_TO_PERSON_PROPERTIES should be kept in sync with
// https://github.com/PostHog/posthog/blob/master/plugin-server/src/utils/db/utils.ts#L60
// The list of campaign parameters that could be considered personal data under e.g. GDPR.
// These can be masked in URLs and properties before being sent to posthog.
exports.PERSONAL_DATA_CAMPAIGN_PARAMS = [
    'gclid', // google ads
    'gclsrc', // google ads 360
    'dclid', // google display ads
    'gbraid', // google ads, web to app
    'wbraid', // google ads, app to web
    'fbclid', // facebook
    'msclkid', // microsoft
    'twclid', // twitter
    'li_fat_id', // linkedin
    'igshid', // instagram
    'ttclid', // tiktok
    'rdt_cid', // reddit
    'epik', // pinterest
    'qclid', // quora
    'sccid', // snapchat
    'irclid', // impact
    '_kx', // klaviyo
];
exports.CAMPAIGN_PARAMS = (0, index_1.extendArray)([
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_content',
    'utm_term',
    'gad_source', // google ads source
    'mc_cid', // mailchimp campaign id
], exports.PERSONAL_DATA_CAMPAIGN_PARAMS);
exports.EVENT_TO_PERSON_PROPERTIES = [
    // mobile params
    '$app_build',
    '$app_name',
    '$app_namespace',
    '$app_version',
    // web params
    '$browser',
    '$browser_version',
    '$device_type',
    '$current_url',
    '$pathname',
    '$os',
    '$os_name', // $os_name is a special case, it's treated as an alias of $os!
    '$os_version',
    '$referring_domain',
    '$referrer',
    '$screen_height',
    '$screen_width',
    '$viewport_height',
    '$viewport_width',
    '$raw_user_agent',
];
exports.MASKED = '<masked>';
// Campaign params that can be read from the cookie store
exports.COOKIE_CAMPAIGN_PARAMS = [
    'li_fat_id', // linkedin
];
function getCampaignParams(customTrackedParams, maskPersonalDataProperties, customPersonalDataProperties) {
    if (!globals_1.document) {
        return {};
    }
    var paramsToMask = maskPersonalDataProperties
        ? (0, index_1.extendArray)([], exports.PERSONAL_DATA_CAMPAIGN_PARAMS, customPersonalDataProperties || [])
        : [];
    // Initially get campaign params from the URL
    var urlCampaignParams = _getCampaignParamsFromUrl((0, request_utils_1.maskQueryParams)(globals_1.document.URL, paramsToMask, exports.MASKED), customTrackedParams);
    // But we can also get some of them from the cookie store
    // For example: https://learn.microsoft.com/en-us/linkedin/marketing/conversions/enabling-first-party-cookies?view=li-lms-2025-05#reading-li_fat_id-from-cookies
    var cookieCampaignParams = _getCampaignParamsFromCookie();
    // Prefer the values found in the urlCampaignParams if possible
    // `extend` will override the values if found in the second argument
    return (0, index_1.extend)(cookieCampaignParams, urlCampaignParams);
}
function _getCampaignParamsFromUrl(url, customParams) {
    var campaign_keywords = exports.CAMPAIGN_PARAMS.concat(customParams || []);
    var params = {};
    (0, index_1.each)(campaign_keywords, function (kwkey) {
        var kw = (0, request_utils_1.getQueryParam)(url, kwkey);
        params[kwkey] = kw ? kw : null;
    });
    return params;
}
function _getCampaignParamsFromCookie() {
    var params = {};
    (0, index_1.each)(exports.COOKIE_CAMPAIGN_PARAMS, function (kwkey) {
        var kw = storage_1.cookieStore._get(kwkey);
        params[kwkey] = kw ? kw : null;
    });
    return params;
}
function _getSearchEngine(referrer) {
    if (!referrer) {
        return null;
    }
    else {
        if (referrer.search(URL_REGEX_PREFIX + 'google.([^/?]*)') === 0) {
            return 'google';
        }
        else if (referrer.search(URL_REGEX_PREFIX + 'bing.com') === 0) {
            return 'bing';
        }
        else if (referrer.search(URL_REGEX_PREFIX + 'yahoo.com') === 0) {
            return 'yahoo';
        }
        else if (referrer.search(URL_REGEX_PREFIX + 'duckduckgo.com') === 0) {
            return 'duckduckgo';
        }
        else {
            return null;
        }
    }
}
function _getSearchInfoFromReferrer(referrer) {
    var search = _getSearchEngine(referrer);
    var param = search != 'yahoo' ? 'q' : 'p';
    var ret = {};
    if (!(0, core_1.isNull)(search)) {
        ret['$search_engine'] = search;
        var keyword = globals_1.document ? (0, request_utils_1.getQueryParam)(globals_1.document.referrer, param) : '';
        if (keyword.length) {
            ret['ph_keyword'] = keyword;
        }
    }
    return ret;
}
function getSearchInfo() {
    var referrer = globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.referrer;
    if (!referrer) {
        return {};
    }
    return _getSearchInfoFromReferrer(referrer);
}
function getBrowserLanguage() {
    return (navigator.language || // Any modern browser
        navigator.userLanguage // IE11
    );
}
function getBrowserLanguagePrefix() {
    var lang = getBrowserLanguage();
    return typeof lang === 'string' ? lang.split('-')[0] : undefined;
}
function getReferrer() {
    return (globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.referrer) || '$direct';
}
function getReferringDomain() {
    var _a;
    if (!(globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.referrer)) {
        return '$direct';
    }
    return ((_a = (0, request_utils_1.convertToURL)(globals_1.document.referrer)) === null || _a === void 0 ? void 0 : _a.host) || '$direct';
}
function getReferrerInfo() {
    return {
        $referrer: getReferrer(),
        $referring_domain: getReferringDomain(),
    };
}
function getPersonInfo(maskPersonalDataProperties, customPersonalDataProperties) {
    var paramsToMask = maskPersonalDataProperties
        ? (0, index_1.extendArray)([], exports.PERSONAL_DATA_CAMPAIGN_PARAMS, customPersonalDataProperties || [])
        : [];
    var url = globals_1.location === null || globals_1.location === void 0 ? void 0 : globals_1.location.href.substring(0, 1000);
    // we're being a bit more economical with bytes here because this is stored in the cookie
    return {
        r: getReferrer().substring(0, 1000),
        u: url ? (0, request_utils_1.maskQueryParams)(url, paramsToMask, exports.MASKED) : undefined,
    };
}
function getPersonPropsFromInfo(info) {
    var _a;
    var referrer = info.r, url = info.u;
    var referring_domain = referrer == null ? undefined : referrer == '$direct' ? '$direct' : (_a = (0, request_utils_1.convertToURL)(referrer)) === null || _a === void 0 ? void 0 : _a.host;
    var props = {
        $referrer: referrer,
        $referring_domain: referring_domain,
    };
    if (url) {
        props['$current_url'] = url;
        var location_1 = (0, request_utils_1.convertToURL)(url);
        props['$host'] = location_1 === null || location_1 === void 0 ? void 0 : location_1.host;
        props['$pathname'] = location_1 === null || location_1 === void 0 ? void 0 : location_1.pathname;
        var campaignParams = _getCampaignParamsFromUrl(url);
        (0, index_1.extend)(props, campaignParams);
    }
    if (referrer) {
        var searchInfo = _getSearchInfoFromReferrer(referrer);
        (0, index_1.extend)(props, searchInfo);
    }
    return props;
}
function getInitialPersonPropsFromInfo(info) {
    var personProps = getPersonPropsFromInfo(info);
    var props = {};
    (0, index_1.each)(personProps, function (val, key) {
        props["$initial_".concat((0, core_1.stripLeadingDollar)(key))] = val;
    });
    return props;
}
function getTimezone() {
    try {
        return Intl.DateTimeFormat().resolvedOptions().timeZone;
    }
    catch (_a) {
        return undefined;
    }
}
function getTimezoneOffset() {
    try {
        return new Date().getTimezoneOffset();
    }
    catch (_a) {
        return undefined;
    }
}
function getEventProperties(maskPersonalDataProperties, customPersonalDataProperties) {
    if (!globals_1.userAgent) {
        return {};
    }
    var paramsToMask = maskPersonalDataProperties
        ? (0, index_1.extendArray)([], exports.PERSONAL_DATA_CAMPAIGN_PARAMS, customPersonalDataProperties || [])
        : [];
    var _a = __read((0, user_agent_utils_1.detectOS)(globals_1.userAgent), 2), os_name = _a[0], os_version = _a[1];
    return (0, index_1.extend)((0, index_1.stripEmptyProperties)({
        $os: os_name,
        $os_version: os_version,
        $browser: (0, user_agent_utils_1.detectBrowser)(globals_1.userAgent, navigator.vendor),
        $device: (0, user_agent_utils_1.detectDevice)(globals_1.userAgent),
        $device_type: (0, user_agent_utils_1.detectDeviceType)(globals_1.userAgent),
        $timezone: getTimezone(),
        $timezone_offset: getTimezoneOffset(),
    }), {
        $current_url: (0, request_utils_1.maskQueryParams)(globals_1.location === null || globals_1.location === void 0 ? void 0 : globals_1.location.href, paramsToMask, exports.MASKED),
        $host: globals_1.location === null || globals_1.location === void 0 ? void 0 : globals_1.location.host,
        $pathname: globals_1.location === null || globals_1.location === void 0 ? void 0 : globals_1.location.pathname,
        $raw_user_agent: globals_1.userAgent.length > 1000 ? globals_1.userAgent.substring(0, 997) + '...' : globals_1.userAgent,
        $browser_version: (0, user_agent_utils_1.detectBrowserVersion)(globals_1.userAgent, navigator.vendor),
        $browser_language: getBrowserLanguage(),
        $browser_language_prefix: getBrowserLanguagePrefix(),
        $screen_height: globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.screen.height,
        $screen_width: globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.screen.width,
        $viewport_height: globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.innerHeight,
        $viewport_width: globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.innerWidth,
        $lib: 'web',
        $lib_version: config_1.default.LIB_VERSION,
        $insert_id: Math.random().toString(36).substring(2, 10) + Math.random().toString(36).substring(2, 10),
        $time: Date.now() / 1000, // epoch time in seconds
    });
}
//# sourceMappingURL=event-utils.js.map