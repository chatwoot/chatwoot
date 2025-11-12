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
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
exports.detectDeviceType = exports.detectDevice = exports.detectOS = exports.detectBrowserVersion = exports.detectBrowser = void 0;
var core_1 = require("@posthog/core");
/**
 * this device detection code is (at time of writing) about 3% of the size of the entire library
 * this is mostly because the identifiers user in regexes and results can't be minified away since
 * they have meaning
 *
 * so, there are some pre-uglifying choices in the code to help reduce the size
 * e.g. many repeated strings are stored as variables and then old-fashioned concatenated together
 *
 * TL;DR here be dragons
 */
var FACEBOOK = 'Facebook';
var MOBILE = 'Mobile';
var IOS = 'iOS';
var ANDROID = 'Android';
var TABLET = 'Tablet';
var ANDROID_TABLET = ANDROID + ' ' + TABLET;
var IPAD = 'iPad';
var APPLE = 'Apple';
var APPLE_WATCH = APPLE + ' Watch';
var SAFARI = 'Safari';
var BLACKBERRY = 'BlackBerry';
var SAMSUNG = 'Samsung';
var SAMSUNG_BROWSER = SAMSUNG + 'Browser';
var SAMSUNG_INTERNET = SAMSUNG + ' Internet';
var CHROME = 'Chrome';
var CHROME_OS = CHROME + ' OS';
var CHROME_IOS = CHROME + ' ' + IOS;
var INTERNET_EXPLORER = 'Internet Explorer';
var INTERNET_EXPLORER_MOBILE = INTERNET_EXPLORER + ' ' + MOBILE;
var OPERA = 'Opera';
var OPERA_MINI = OPERA + ' Mini';
var EDGE = 'Edge';
var MICROSOFT_EDGE = 'Microsoft ' + EDGE;
var FIREFOX = 'Firefox';
var FIREFOX_IOS = FIREFOX + ' ' + IOS;
var NINTENDO = 'Nintendo';
var PLAYSTATION = 'PlayStation';
var XBOX = 'Xbox';
var ANDROID_MOBILE = ANDROID + ' ' + MOBILE;
var MOBILE_SAFARI = MOBILE + ' ' + SAFARI;
var WINDOWS = 'Windows';
var WINDOWS_PHONE = WINDOWS + ' Phone';
var NOKIA = 'Nokia';
var OUYA = 'Ouya';
var GENERIC = 'Generic';
var GENERIC_MOBILE = GENERIC + ' ' + MOBILE.toLowerCase();
var GENERIC_TABLET = GENERIC + ' ' + TABLET.toLowerCase();
var KONQUEROR = 'Konqueror';
var BROWSER_VERSION_REGEX_SUFFIX = '(\\d+(\\.\\d+)?)';
var DEFAULT_BROWSER_VERSION_REGEX = new RegExp('Version/' + BROWSER_VERSION_REGEX_SUFFIX);
var XBOX_REGEX = new RegExp(XBOX, 'i');
var PLAYSTATION_REGEX = new RegExp(PLAYSTATION + ' \\w+', 'i');
var NINTENDO_REGEX = new RegExp(NINTENDO + ' \\w+', 'i');
var BLACKBERRY_REGEX = new RegExp(BLACKBERRY + '|PlayBook|BB10', 'i');
var windowsVersionMap = {
    'NT3.51': 'NT 3.11',
    'NT4.0': 'NT 4.0',
    '5.0': '2000',
    '5.1': 'XP',
    '5.2': 'XP',
    '6.0': 'Vista',
    '6.1': '7',
    '6.2': '8',
    '6.3': '8.1',
    '6.4': '10',
    '10.0': '10',
};
/**
 * Safari detection turns out to be complicated. For e.g. https://stackoverflow.com/a/29696509
 * We can be slightly loose because some options have been ruled out (e.g. firefox on iOS)
 * before this check is made
 */
function isSafari(userAgent) {
    return (0, core_1.includes)(userAgent, SAFARI) && !(0, core_1.includes)(userAgent, CHROME) && !(0, core_1.includes)(userAgent, ANDROID);
}
var safariCheck = function (ua, vendor) { return (vendor && (0, core_1.includes)(vendor, APPLE)) || isSafari(ua); };
/**
 * This function detects which browser is running this script.
 * The order of the checks are important since many user agents
 * include keywords used in later checks.
 */
var detectBrowser = function (user_agent, vendor) {
    vendor = vendor || ''; // vendor is undefined for at least IE9
    if ((0, core_1.includes)(user_agent, ' OPR/') && (0, core_1.includes)(user_agent, 'Mini')) {
        return OPERA_MINI;
    }
    else if ((0, core_1.includes)(user_agent, ' OPR/')) {
        return OPERA;
    }
    else if (BLACKBERRY_REGEX.test(user_agent)) {
        return BLACKBERRY;
    }
    else if ((0, core_1.includes)(user_agent, 'IE' + MOBILE) || (0, core_1.includes)(user_agent, 'WPDesktop')) {
        return INTERNET_EXPLORER_MOBILE;
    }
    // https://developer.samsung.com/internet/user-agent-string-format
    else if ((0, core_1.includes)(user_agent, SAMSUNG_BROWSER)) {
        return SAMSUNG_INTERNET;
    }
    else if ((0, core_1.includes)(user_agent, EDGE) || (0, core_1.includes)(user_agent, 'Edg/')) {
        return MICROSOFT_EDGE;
    }
    else if ((0, core_1.includes)(user_agent, 'FBIOS')) {
        return FACEBOOK + ' ' + MOBILE;
    }
    else if ((0, core_1.includes)(user_agent, 'UCWEB') || (0, core_1.includes)(user_agent, 'UCBrowser')) {
        return 'UC Browser';
    }
    else if ((0, core_1.includes)(user_agent, 'CriOS')) {
        return CHROME_IOS; // why not just Chrome?
    }
    else if ((0, core_1.includes)(user_agent, 'CrMo')) {
        return CHROME;
    }
    else if ((0, core_1.includes)(user_agent, CHROME)) {
        return CHROME;
    }
    else if ((0, core_1.includes)(user_agent, ANDROID) && (0, core_1.includes)(user_agent, SAFARI)) {
        return ANDROID_MOBILE;
    }
    else if ((0, core_1.includes)(user_agent, 'FxiOS')) {
        return FIREFOX_IOS;
    }
    else if ((0, core_1.includes)(user_agent.toLowerCase(), KONQUEROR.toLowerCase())) {
        return KONQUEROR;
    }
    else if (safariCheck(user_agent, vendor)) {
        return (0, core_1.includes)(user_agent, MOBILE) ? MOBILE_SAFARI : SAFARI;
    }
    else if ((0, core_1.includes)(user_agent, FIREFOX)) {
        return FIREFOX;
    }
    else if ((0, core_1.includes)(user_agent, 'MSIE') || (0, core_1.includes)(user_agent, 'Trident/')) {
        return INTERNET_EXPLORER;
    }
    else if ((0, core_1.includes)(user_agent, 'Gecko')) {
        return FIREFOX;
    }
    return '';
};
exports.detectBrowser = detectBrowser;
var versionRegexes = (_a = {},
    _a[INTERNET_EXPLORER_MOBILE] = [new RegExp('rv:' + BROWSER_VERSION_REGEX_SUFFIX)],
    _a[MICROSOFT_EDGE] = [new RegExp(EDGE + '?\\/' + BROWSER_VERSION_REGEX_SUFFIX)],
    _a[CHROME] = [new RegExp('(' + CHROME + '|CrMo)\\/' + BROWSER_VERSION_REGEX_SUFFIX)],
    _a[CHROME_IOS] = [new RegExp('CriOS\\/' + BROWSER_VERSION_REGEX_SUFFIX)],
    _a['UC Browser'] = [new RegExp('(UCBrowser|UCWEB)\\/' + BROWSER_VERSION_REGEX_SUFFIX)],
    _a[SAFARI] = [DEFAULT_BROWSER_VERSION_REGEX],
    _a[MOBILE_SAFARI] = [DEFAULT_BROWSER_VERSION_REGEX],
    _a[OPERA] = [new RegExp('(' + OPERA + '|OPR)\\/' + BROWSER_VERSION_REGEX_SUFFIX)],
    _a[FIREFOX] = [new RegExp(FIREFOX + '\\/' + BROWSER_VERSION_REGEX_SUFFIX)],
    _a[FIREFOX_IOS] = [new RegExp('FxiOS\\/' + BROWSER_VERSION_REGEX_SUFFIX)],
    _a[KONQUEROR] = [new RegExp('Konqueror[:/]?' + BROWSER_VERSION_REGEX_SUFFIX, 'i')],
    // not every blackberry user agent has the version after the name
    _a[BLACKBERRY] = [new RegExp(BLACKBERRY + ' ' + BROWSER_VERSION_REGEX_SUFFIX), DEFAULT_BROWSER_VERSION_REGEX],
    _a[ANDROID_MOBILE] = [new RegExp('android\\s' + BROWSER_VERSION_REGEX_SUFFIX, 'i')],
    _a[SAMSUNG_INTERNET] = [new RegExp(SAMSUNG_BROWSER + '\\/' + BROWSER_VERSION_REGEX_SUFFIX)],
    _a[INTERNET_EXPLORER] = [new RegExp('(rv:|MSIE )' + BROWSER_VERSION_REGEX_SUFFIX)],
    _a.Mozilla = [new RegExp('rv:' + BROWSER_VERSION_REGEX_SUFFIX)],
    _a);
/**
 * This function detects which browser version is running this script,
 * parsing major and minor version (e.g., 42.1). User agent strings from:
 * http://www.useragentstring.com/pages/useragentstring.php
 *
 * `navigator.vendor` is passed in and used to help with detecting certain browsers
 * NB `navigator.vendor` is deprecated and not present in every browser
 */
var detectBrowserVersion = function (userAgent, vendor) {
    var browser = (0, exports.detectBrowser)(userAgent, vendor);
    var regexes = versionRegexes[browser];
    if ((0, core_1.isUndefined)(regexes)) {
        return null;
    }
    for (var i = 0; i < regexes.length; i++) {
        var regex = regexes[i];
        var matches = userAgent.match(regex);
        if (matches) {
            return parseFloat(matches[matches.length - 2]);
        }
    }
    return null;
};
exports.detectBrowserVersion = detectBrowserVersion;
// to avoid repeating regexes or calling them twice, we have an array of matches
// the first regex that matches uses its matcher function to return the result
var osMatchers = [
    [
        new RegExp(XBOX + '; ' + XBOX + ' (.*?)[);]', 'i'),
        function (match) {
            return [XBOX, (match && match[1]) || ''];
        },
    ],
    [new RegExp(NINTENDO, 'i'), [NINTENDO, '']],
    [new RegExp(PLAYSTATION, 'i'), [PLAYSTATION, '']],
    [BLACKBERRY_REGEX, [BLACKBERRY, '']],
    [
        new RegExp(WINDOWS, 'i'),
        function (_, user_agent) {
            if (/Phone/.test(user_agent) || /WPDesktop/.test(user_agent)) {
                return [WINDOWS_PHONE, ''];
            }
            // not all JS versions support negative lookbehind, so we need two checks here
            if (new RegExp(MOBILE).test(user_agent) && !/IEMobile\b/.test(user_agent)) {
                return [WINDOWS + ' ' + MOBILE, ''];
            }
            var match = /Windows NT ([0-9.]+)/i.exec(user_agent);
            if (match && match[1]) {
                var version = match[1];
                var osVersion = windowsVersionMap[version] || '';
                if (/arm/i.test(user_agent)) {
                    osVersion = 'RT';
                }
                return [WINDOWS, osVersion];
            }
            return [WINDOWS, ''];
        },
    ],
    [
        /((iPhone|iPad|iPod).*?OS (\d+)_(\d+)_?(\d+)?|iPhone)/,
        function (match) {
            if (match && match[3]) {
                var versionParts = [match[3], match[4], match[5] || '0'];
                return [IOS, versionParts.join('.')];
            }
            return [IOS, ''];
        },
    ],
    [
        /(watch.*\/(\d+\.\d+\.\d+)|watch os,(\d+\.\d+),)/i,
        function (match) {
            // e.g. Watch4,3/5.3.8 (16U680)
            var version = '';
            if (match && match.length >= 3) {
                version = (0, core_1.isUndefined)(match[2]) ? match[3] : match[2];
            }
            return ['watchOS', version];
        },
    ],
    [
        new RegExp('(' + ANDROID + ' (\\d+)\\.(\\d+)\\.?(\\d+)?|' + ANDROID + ')', 'i'),
        function (match) {
            if (match && match[2]) {
                var versionParts = [match[2], match[3], match[4] || '0'];
                return [ANDROID, versionParts.join('.')];
            }
            return [ANDROID, ''];
        },
    ],
    [
        /Mac OS X (\d+)[_.](\d+)[_.]?(\d+)?/i,
        function (match) {
            var result = ['Mac OS X', ''];
            if (match && match[1]) {
                var versionParts = [match[1], match[2], match[3] || '0'];
                result[1] = versionParts.join('.');
            }
            return result;
        },
    ],
    [
        /Mac/i,
        // mop up a few non-standard UAs that should match mac
        ['Mac OS X', ''],
    ],
    [/CrOS/, [CHROME_OS, '']],
    [/Linux|debian/i, ['Linux', '']],
];
var detectOS = function (user_agent) {
    for (var i = 0; i < osMatchers.length; i++) {
        var _a = __read(osMatchers[i], 2), rgex = _a[0], resultOrFn = _a[1];
        var match = rgex.exec(user_agent);
        var result = match && ((0, core_1.isFunction)(resultOrFn) ? resultOrFn(match, user_agent) : resultOrFn);
        if (result) {
            return result;
        }
    }
    return ['', ''];
};
exports.detectOS = detectOS;
var detectDevice = function (user_agent) {
    if (NINTENDO_REGEX.test(user_agent)) {
        return NINTENDO;
    }
    else if (PLAYSTATION_REGEX.test(user_agent)) {
        return PLAYSTATION;
    }
    else if (XBOX_REGEX.test(user_agent)) {
        return XBOX;
    }
    else if (new RegExp(OUYA, 'i').test(user_agent)) {
        return OUYA;
    }
    else if (new RegExp('(' + WINDOWS_PHONE + '|WPDesktop)', 'i').test(user_agent)) {
        return WINDOWS_PHONE;
    }
    else if (/iPad/.test(user_agent)) {
        return IPAD;
    }
    else if (/iPod/.test(user_agent)) {
        return 'iPod Touch';
    }
    else if (/iPhone/.test(user_agent)) {
        return 'iPhone';
    }
    else if (/(watch)(?: ?os[,/]|\d,\d\/)[\d.]+/i.test(user_agent)) {
        return APPLE_WATCH;
    }
    else if (BLACKBERRY_REGEX.test(user_agent)) {
        return BLACKBERRY;
    }
    else if (/(kobo)\s(ereader|touch)/i.test(user_agent)) {
        return 'Kobo';
    }
    else if (new RegExp(NOKIA, 'i').test(user_agent)) {
        return NOKIA;
    }
    else if (
    // Kindle Fire without Silk / Echo Show
    /(kf[a-z]{2}wi|aeo[c-r]{2})( bui|\))/i.test(user_agent) ||
        // Kindle Fire HD
        /(kf[a-z]+)( bui|\)).+silk\//i.test(user_agent)) {
        return 'Kindle Fire';
    }
    else if (/(Android|ZTE)/i.test(user_agent)) {
        if (!new RegExp(MOBILE).test(user_agent) ||
            /(9138B|TB782B|Nexus [97]|pixel c|HUAWEISHT|BTV|noble nook|smart ultra 6)/i.test(user_agent)) {
            if ((/pixel[\daxl ]{1,6}/i.test(user_agent) && !/pixel c/i.test(user_agent)) ||
                /(huaweimed-al00|tah-|APA|SM-G92|i980|zte|U304AA)/i.test(user_agent) ||
                (/lmy47v/i.test(user_agent) && !/QTAQZ3/i.test(user_agent))) {
                return ANDROID;
            }
            return ANDROID_TABLET;
        }
        else {
            return ANDROID;
        }
    }
    else if (new RegExp('(pda|' + MOBILE + ')', 'i').test(user_agent)) {
        return GENERIC_MOBILE;
    }
    else if (new RegExp(TABLET, 'i').test(user_agent) && !new RegExp(TABLET + ' pc', 'i').test(user_agent)) {
        return GENERIC_TABLET;
    }
    else {
        return '';
    }
};
exports.detectDevice = detectDevice;
var detectDeviceType = function (user_agent) {
    var device = (0, exports.detectDevice)(user_agent);
    if (device === IPAD ||
        device === ANDROID_TABLET ||
        device === 'Kobo' ||
        device === 'Kindle Fire' ||
        device === GENERIC_TABLET) {
        return TABLET;
    }
    else if (device === NINTENDO || device === XBOX || device === PLAYSTATION || device === OUYA) {
        return 'Console';
    }
    else if (device === APPLE_WATCH) {
        return 'Wearable';
    }
    else if (device) {
        return MOBILE;
    }
    else {
        return 'Desktop';
    }
};
exports.detectDeviceType = detectDeviceType;
//# sourceMappingURL=user-agent-utils.js.map