"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isLikelyBot = exports.isBlockedUA = exports.DEFAULT_BLOCKED_UA_STRS = void 0;
exports.DEFAULT_BLOCKED_UA_STRS = [
    // Random assortment of bots
    'amazonbot',
    'amazonproductbot',
    'app.hypefactors.com', // Buck, but "buck" is too short to be safe to block (https://app.hypefactors.com/media-monitoring/about.htm)
    'applebot',
    'archive.org_bot',
    'awariobot',
    'backlinksextendedbot',
    'baiduspider',
    'bingbot',
    'bingpreview',
    'chrome-lighthouse',
    'dataforseobot',
    'deepscan',
    'duckduckbot',
    'facebookexternal',
    'facebookcatalog',
    'http://yandex.com/bots',
    'hubspot',
    'ia_archiver',
    'leikibot',
    'linkedinbot',
    'meta-externalagent',
    'mj12bot',
    'msnbot',
    'nessus',
    'petalbot',
    'pinterest',
    'prerender',
    'rogerbot',
    'screaming frog',
    'sebot-wa',
    'sitebulb',
    'slackbot',
    'slurp',
    'trendictionbot',
    'turnitin',
    'twitterbot',
    'vercel-screenshot',
    'vercelbot',
    'yahoo! slurp',
    'yandexbot',
    'zoombot',
    // Bot-like words, maybe we should block `bot` entirely?
    'bot.htm',
    'bot.php',
    '(bot;',
    'bot/',
    'crawler',
    // Ahrefs: https://ahrefs.com/seo/glossary/ahrefsbot
    'ahrefsbot',
    'ahrefssiteaudit',
    // Semrush bots: https://www.semrush.com/bot/
    'semrushbot',
    'siteauditbot',
    'splitsignalbot',
    // AI Crawlers
    'gptbot',
    'oai-searchbot',
    'chatgpt-user',
    'perplexitybot',
    // Uptime-like stuff
    'better uptime bot',
    'sentryuptimebot',
    'uptimerobot',
    // headless browsers
    'headlesschrome',
    'cypress',
    // we don't block electron here, as many customers use posthog-js in electron apps
    // a whole bunch of goog-specific crawlers
    // https://developers.google.com/search/docs/advanced/crawling/overview-google-crawlers
    'google-hoteladsverifier',
    'adsbot-google',
    'apis-google',
    'duplexweb-google',
    'feedfetcher-google',
    'google favicon',
    'google web preview',
    'google-read-aloud',
    'googlebot',
    'googleother',
    'google-cloudvertexbot',
    'googleweblight',
    'mediapartners-google',
    'storebot-google',
    'google-inspectiontool',
    'bytespider',
];
/**
 * Block various web spiders from executing our JS and sending false capturing data
 */
var isBlockedUA = function (ua, customBlockedUserAgents) {
    if (!ua) {
        return false;
    }
    var uaLower = ua.toLowerCase();
    return exports.DEFAULT_BLOCKED_UA_STRS.concat(customBlockedUserAgents || []).some(function (blockedUA) {
        var blockedUaLower = blockedUA.toLowerCase();
        // can't use includes because IE 11 :/
        return uaLower.indexOf(blockedUaLower) !== -1;
    });
};
exports.isBlockedUA = isBlockedUA;
var isLikelyBot = function (navigator, customBlockedUserAgents) {
    if (!navigator) {
        return false;
    }
    var ua = navigator.userAgent;
    if (ua) {
        if ((0, exports.isBlockedUA)(ua, customBlockedUserAgents)) {
            return true;
        }
    }
    try {
        // eslint-disable-next-line compat/compat
        var uaData = navigator === null || navigator === void 0 ? void 0 : navigator.userAgentData;
        if ((uaData === null || uaData === void 0 ? void 0 : uaData.brands) && uaData.brands.some(function (brandObj) { return (0, exports.isBlockedUA)(brandObj === null || brandObj === void 0 ? void 0 : brandObj.brand, customBlockedUserAgents); })) {
            return true;
        }
    }
    catch (_a) {
        // ignore the error, we were using experimental browser features
    }
    return !!navigator.webdriver;
    // There's some more enhancements we could make in this area, e.g. it's possible to check if Chrome dev tools are
    // open, which will detect some bots that are trying to mask themselves and might get past the checks above.
    // However, this would give false positives for actual humans who have dev tools open.
    // We could also use the data in navigator.userAgentData.getHighEntropyValues() to detect bots, but we should wait
    // until this stops being experimental. The MDN docs imply that this might eventually require user permission.
    // See https://developer.mozilla.org/en-US/docs/Web/API/NavigatorUAData/getHighEntropyValues
    // It would be very bad if posthog-js caused a permission prompt to appear on every page load.
};
exports.isLikelyBot = isLikelyBot;
//# sourceMappingURL=blocked-uas.js.map