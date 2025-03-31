/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
var _a, _b;
var SCOPED = '__scoped';
// Note, explicitly use `var` here so that this can be re-defined when
// bundled.
// eslint-disable-next-line no-var
var DEV_MODE = true;
var polyfillSupport = function (_a) {
    var ReactiveElement = _a.ReactiveElement;
    // polyfill-support is only needed if ShadyCSS or the ApplyShim is in use
    // We test at the point of patching, which makes it safe to load
    // webcomponentsjs and polyfill-support in either order
    if (window.ShadyCSS === undefined ||
        (window.ShadyCSS.nativeShadow && !window.ShadyCSS.ApplyShim)) {
        return;
    }
    // console.log(
    //   '%c Making ReactiveElement compatible with ShadyDOM/CSS.',
    //   'color: lightgreen; font-style: italic'
    // );
    var elementProto = ReactiveElement.prototype;
    // In noPatch mode, patch the ReactiveElement prototype so that no
    // ReactiveElements must be wrapped.
    if (window.ShadyDOM &&
        window.ShadyDOM.inUse &&
        window.ShadyDOM.noPatch === true) {
        window.ShadyDOM.patchElementProto(elementProto);
    }
    /**
     * Patch to apply adoptedStyleSheets via ShadyCSS
     */
    var createRenderRoot = elementProto.createRenderRoot;
    elementProto.createRenderRoot = function () {
        var _a, _b, _c;
        // Pass the scope to render options so that it gets to lit-html for proper
        // scoping via ShadyCSS.
        var name = this.localName;
        // If using native Shadow DOM must adoptStyles normally,
        // otherwise do nothing.
        if (window.ShadyCSS.nativeShadow) {
            return createRenderRoot.call(this);
        }
        else {
            if (!this.constructor.hasOwnProperty(SCOPED)) {
                this.constructor[SCOPED] =
                    true;
                // Use ShadyCSS's `prepareAdoptedCssText` to shim adoptedStyleSheets.
                var css = this.constructor.elementStyles.map(function (v) {
                    return v instanceof CSSStyleSheet
                        ? Array.from(v.cssRules).reduce(function (a, r) { return (a += r.cssText); }, '')
                        : v.cssText;
                });
                (_b = (_a = window.ShadyCSS) === null || _a === void 0 ? void 0 : _a.ScopingShim) === null || _b === void 0 ? void 0 : _b.prepareAdoptedCssText(css, name);
                if (this.constructor._$handlesPrepareStyles === undefined) {
                    window.ShadyCSS.prepareTemplateStyles(document.createElement('template'), name);
                }
            }
            return ((_c = this.shadowRoot) !== null && _c !== void 0 ? _c : this.attachShadow(this.constructor
                .shadowRootOptions));
        }
    };
    /**
     * Patch connectedCallback to apply ShadyCSS custom properties shimming.
     */
    var connectedCallback = elementProto.connectedCallback;
    elementProto.connectedCallback = function () {
        connectedCallback.call(this);
        // Note, must do first update separately so that we're ensured
        // that rendering has completed before calling this.
        if (this.hasUpdated) {
            window.ShadyCSS.styleElement(this);
        }
    };
    /**
     * Patch update to apply ShadyCSS custom properties shimming for first
     * update.
     */
    var didUpdate = elementProto._$didUpdate;
    elementProto._$didUpdate = function (changedProperties) {
        // Note, must do first update here so rendering has completed before
        // calling this and styles are correct by updated/firstUpdated.
        if (!this.hasUpdated) {
            window.ShadyCSS.styleElement(this);
        }
        didUpdate.call(this, changedProperties);
    };
};
if (DEV_MODE) {
    (_a = globalThis.reactiveElementPolyfillSupportDevMode) !== null && _a !== void 0 ? _a : (globalThis.reactiveElementPolyfillSupportDevMode = polyfillSupport);
}
else {
    (_b = globalThis.reactiveElementPolyfillSupport) !== null && _b !== void 0 ? _b : (globalThis.reactiveElementPolyfillSupport = polyfillSupport);
}
export {};
//# sourceMappingURL=polyfill-support.js.map