/**
 * @file detect-browser.js
 * @since 2.0.0
 */

import window from 'global/window';

/**
 * Browser detector.
 *
 * @private
 * @return {object} result containing browser, version and minVersion
 *     properties.
 */
const detectBrowser = function() {
    // returned result object
    let result = {};
    result.browser = null;
    result.version = null;
    result.minVersion = null;

    // fail early if it's not a browser
    if (typeof window === 'undefined' || !window.navigator) {
        result.browser = 'Not a supported browser.';
        return result;
    }

    if (navigator.mozGetUserMedia) { // Firefox.
        result.browser = 'firefox';
        result.version = extractVersion(navigator.userAgent,
            /Firefox\/(\d+)\./, 1);
        result.minVersion = 31;
    } else if (navigator.webkitGetUserMedia) {
        // Chrome, Chromium, Webview, Opera.
        // Version matches Chrome/WebRTC version.
        result.browser = 'chrome';
        result.version = extractVersion(navigator.userAgent,
            /Chrom(e|ium)\/(\d+)\./, 2); // buddy ignore:line
        result.minVersion = 38;
    } else if (navigator.mediaDevices &&
               navigator.userAgent.match(/Edge\/(\d+).(\d+)$/)) { // Edge.
        result.browser = 'edge';
        result.version = extractVersion(navigator.userAgent,
            /Edge\/(\d+).(\d+)$/, 2); // buddy ignore:line
        result.minVersion = 10547;
    } else if (window.RTCPeerConnection &&
        navigator.userAgent.match(/AppleWebKit\/(\d+)\./)) { // Safari.
        result.browser = 'safari';
        result.version = extractVersion(navigator.userAgent,
            /AppleWebKit\/(\d+)\./, 1);
    } else {
        // Default fallthrough: not supported.
        result.browser = 'Not a supported browser.';
        return result;
    }

    return result;
};

/**
 * Extract browser version out of the provided user agent string.
 *
 * @private
 * @param {!string} uastring - userAgent string.
 * @param {!string} expr - Regular expression used as match criteria.
 * @param {!number} pos - position in the version string to be
 *     returned.
 * @return {!number} browser version.
 */
const extractVersion = function(uastring, expr, pos) {
    let match = uastring.match(expr);
    return match && match.length >= pos && parseInt(match[pos], 10); // buddy ignore:line
};

const isEdge = function() {
    return detectBrowser().browser === 'edge';
};

const isSafari = function() {
    return detectBrowser().browser === 'safari';
};

const isOpera = function() {
    return !!window.opera || navigator.userAgent.indexOf('OPR/') !== -1;
};

const isChrome = function() {
    return detectBrowser().browser === 'chrome';
};

const isFirefox = function() {
    return detectBrowser().browser === 'firefox';
};

export {
    detectBrowser, isEdge, isOpera, isChrome, isSafari, isFirefox
};
