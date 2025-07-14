"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.pageEnrichment = exports.pageDefaults = exports.canonicalUrl = void 0;
/**
 * Get the current page's canonical URL.
 *
 * @return {string|undefined}
 */
function canonical() {
    var tags = document.getElementsByTagName('link');
    var canon = '';
    Array.prototype.slice.call(tags).forEach(function (tag) {
        if (tag.getAttribute('rel') === 'canonical') {
            canon = tag.getAttribute('href');
        }
    });
    return canon;
}
/**
 * Return the canonical path for the page.
 */
function canonicalPath() {
    var canon = canonical();
    if (!canon) {
        return window.location.pathname;
    }
    var a = document.createElement('a');
    a.href = canon;
    var pathname = !a.pathname.startsWith('/') ? '/' + a.pathname : a.pathname;
    return pathname;
}
/**
 * Return the canonical URL for the page concat the given `search`
 * and strip the hash.
 */
function canonicalUrl(search) {
    if (search === void 0) { search = ''; }
    var canon = canonical();
    if (canon) {
        return canon.includes('?') ? canon : "".concat(canon).concat(search);
    }
    var url = window.location.href;
    var i = url.indexOf('#');
    return i === -1 ? url : url.slice(0, i);
}
exports.canonicalUrl = canonicalUrl;
/**
 * Return a default `options.context.page` object.
 *
 * https://segment.com/docs/spec/page/#properties
 */
function pageDefaults() {
    return {
        path: canonicalPath(),
        referrer: document.referrer,
        search: location.search,
        title: document.title,
        url: canonicalUrl(location.search),
    };
}
exports.pageDefaults = pageDefaults;
function enrichPageContext(ctx) {
    var _a;
    var event = ctx.event;
    event.context = event.context || {};
    var pageContext = pageDefaults();
    var pageProps = (_a = event.properties) !== null && _a !== void 0 ? _a : {};
    Object.keys(pageContext).forEach(function (key) {
        if (pageProps[key]) {
            pageContext[key] = pageProps[key];
        }
    });
    if (event.context.page) {
        pageContext = Object.assign({}, pageContext, event.context.page);
    }
    event.context = Object.assign({}, event.context, {
        page: pageContext,
    });
    ctx.event = event;
    return ctx;
}
exports.pageEnrichment = {
    name: 'Page Enrichment',
    version: '0.1.0',
    isLoaded: function () { return true; },
    load: function () { return Promise.resolve(); },
    type: 'before',
    page: function (ctx) {
        ctx.event.properties = Object.assign({}, pageDefaults(), ctx.event.properties);
        if (ctx.event.name) {
            ctx.event.properties.name = ctx.event.name;
        }
        return enrichPageContext(ctx);
    },
    alias: enrichPageContext,
    track: enrichPageContext,
    identify: enrichPageContext,
    group: enrichPageContext,
};
//# sourceMappingURL=index.js.map