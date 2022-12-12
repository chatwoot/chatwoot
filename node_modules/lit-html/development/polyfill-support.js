/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
var _a, _b;
// Scopes that have had styling prepared. Note, must only be done once per
// scope.
var styledScopes = new Set();
// Map of css per scope. This is collected during first scope render, used when
// styling is prepared, and then discarded.
var scopeCssStore = new Map();
var ENABLE_SHADYDOM_NOPATCH = true;
// Note, explicitly use `var` here so that this can be re-defined when
// bundled.
// eslint-disable-next-line no-var
var DEV_MODE = true;
/**
 * lit-html patches. These properties cannot be renamed.
 * * ChildPart.prototype._$getTemplate
 * * ChildPart.prototype._$setValue
 */
var polyfillSupport = function (Template, ChildPart) {
    var _a, _b;
    // polyfill-support is only needed if ShadyCSS or the ApplyShim is in use
    // We test at the point of patching, which makes it safe to load
    // webcomponentsjs and polyfill-support in either order
    if (window.ShadyCSS === undefined ||
        (window.ShadyCSS.nativeShadow && !window.ShadyCSS.ApplyShim)) {
        return;
    }
    // console.log(
    //   '%c Making lit-html compatible with ShadyDOM/CSS.',
    //   'color: lightgreen; font-style: italic'
    // );
    var wrap = ENABLE_SHADYDOM_NOPATCH &&
        ((_a = window.ShadyDOM) === null || _a === void 0 ? void 0 : _a.inUse) &&
        ((_b = window.ShadyDOM) === null || _b === void 0 ? void 0 : _b.noPatch) === true
        ? window.ShadyDOM.wrap
        : function (node) { return node; };
    var needsPrepareStyles = function (name) {
        return name !== undefined && !styledScopes.has(name);
    };
    var cssForScope = function (name) {
        var scopeCss = scopeCssStore.get(name);
        if (scopeCss === undefined) {
            scopeCssStore.set(name, (scopeCss = []));
        }
        return scopeCss;
    };
    var prepareStyles = function (name, template) {
        // Get styles
        var scopeCss = cssForScope(name);
        var hasScopeCss = scopeCss.length !== 0;
        if (hasScopeCss) {
            var style = document.createElement('style');
            style.textContent = scopeCss.join('\n');
            // Note, it's important to add the style to the *end* of the template so
            // it doesn't mess up part indices.
            template.content.appendChild(style);
        }
        // Mark this scope as styled.
        styledScopes.add(name);
        // Remove stored data since it's no longer needed.
        scopeCssStore.delete(name);
        // ShadyCSS removes scopes and removes the style under ShadyDOM and leaves
        // it under native Shadow DOM
        window.ShadyCSS.prepareTemplateStyles(template, name);
        // Note, under native Shadow DOM, the style is added to the beginning of the
        // template. It must be moved to the *end* of the template so it doesn't
        // mess up part indices.
        if (hasScopeCss && window.ShadyCSS.nativeShadow) {
            // If there were styles but the CSS text was empty, ShadyCSS will
            // eliminate the style altogether, so the style here could be null
            var style = template.content.querySelector('style');
            if (style !== null) {
                template.content.appendChild(style);
            }
        }
    };
    var scopedTemplateCache = new Map();
    /**
     * Override to extract style elements from the template
     * and store all style.textContent in the shady scope data.
     * Note, it's ok to patch Template since it's only used via ChildPart.
     */
    var originalCreateElement = Template.createElement;
    Template.createElement = function (html, options) {
        var element = originalCreateElement.call(Template, html, options);
        var scope = options === null || options === void 0 ? void 0 : options.scope;
        if (scope !== undefined) {
            if (!window.ShadyCSS.nativeShadow) {
                window.ShadyCSS.prepareTemplateDom(element, scope);
            }
            // Process styles only if this scope is being prepared. Otherwise,
            // leave styles as is for back compat with Lit1.
            if (needsPrepareStyles(scope)) {
                var scopeCss = cssForScope(scope);
                // Remove styles and store textContent.
                var styles = element.content.querySelectorAll('style');
                // Store the css in this template in the scope css and remove the <style>
                // from the template _before_ the node-walk captures part indices
                scopeCss.push.apply(scopeCss, Array.from(styles).map(function (style) {
                    var _a;
                    (_a = style.parentNode) === null || _a === void 0 ? void 0 : _a.removeChild(style);
                    return style.textContent;
                }));
            }
        }
        return element;
    };
    var renderContainer = document.createDocumentFragment();
    var renderContainerMarker = document.createComment('');
    var childPartProto = ChildPart.prototype;
    /**
     * Patch to apply gathered css via ShadyCSS. This is done only once per scope.
     */
    var setValue = childPartProto._$setValue;
    childPartProto._$setValue = function (value, directiveParent) {
        var _a, _b, _c;
        if (directiveParent === void 0) { directiveParent = this; }
        var container = wrap(this._$startNode).parentNode;
        var scope = (_a = this.options) === null || _a === void 0 ? void 0 : _a.scope;
        if (container instanceof ShadowRoot && needsPrepareStyles(scope)) {
            // Note, @apply requires outer => inner scope rendering on initial
            // scope renders to apply property values correctly. Style preparation
            // is tied to rendering into `shadowRoot`'s and this is typically done by
            // custom elements. If this is done in `connectedCallback`, as is typical,
            // the code below ensures the right order since content is rendered
            // into a fragment first so the hosting element can prepare styles first.
            // If rendering is done in the constructor, this won't work, but that's
            // not supported in ShadyDOM anyway.
            var startNode = this._$startNode;
            var endNode = this._$endNode;
            // Temporarily move this part into the renderContainer.
            renderContainer.appendChild(renderContainerMarker);
            this._$startNode = renderContainerMarker;
            this._$endNode = null;
            // Note, any nested template results render here and their styles will
            // be extracted and collected.
            setValue.call(this, value, directiveParent);
            // Get the template for this result or create a dummy one if a result
            // is not being rendered.
            // This property needs to remain unminified.
            var template = ((_b = value) === null || _b === void 0 ? void 0 : _b['_$litType$'])
                ? this._$committedValue._$template.el
                : document.createElement('template');
            prepareStyles(scope, template);
            // Note, this is the temporary startNode.
            renderContainer.removeChild(renderContainerMarker);
            // When using native Shadow DOM, include prepared style in shadowRoot.
            if ((_c = window.ShadyCSS) === null || _c === void 0 ? void 0 : _c.nativeShadow) {
                var style = template.content.querySelector('style');
                if (style !== null) {
                    renderContainer.appendChild(style.cloneNode(true));
                }
            }
            container.insertBefore(renderContainer, endNode);
            // Move part back to original container.
            this._$startNode = startNode;
            this._$endNode = endNode;
        }
        else {
            setValue.call(this, value, directiveParent);
        }
    };
    /**
     * Patch ChildPart._$getTemplate to look up templates in a cache bucketed
     * by element name.
     */
    childPartProto._$getTemplate = function (result) {
        var _a;
        var scope = (_a = this.options) === null || _a === void 0 ? void 0 : _a.scope;
        var templateCache = scopedTemplateCache.get(scope);
        if (templateCache === undefined) {
            scopedTemplateCache.set(scope, (templateCache = new Map()));
        }
        var template = templateCache.get(result.strings);
        if (template === undefined) {
            templateCache.set(result.strings, (template = new Template(result, this.options)));
        }
        return template;
    };
};
if (ENABLE_SHADYDOM_NOPATCH) {
    polyfillSupport.noPatchSupported = ENABLE_SHADYDOM_NOPATCH;
}
if (DEV_MODE) {
    (_a = globalThis.litHtmlPolyfillSupportDevMode) !== null && _a !== void 0 ? _a : (globalThis.litHtmlPolyfillSupportDevMode = polyfillSupport);
}
else {
    (_b = globalThis.litHtmlPolyfillSupport) !== null && _b !== void 0 ? _b : (globalThis.litHtmlPolyfillSupport = polyfillSupport);
}
export {};
//# sourceMappingURL=polyfill-support.js.map