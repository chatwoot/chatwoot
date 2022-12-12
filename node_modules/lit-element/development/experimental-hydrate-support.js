/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
import { render } from 'lit-html';
import { hydrate } from 'lit-html/experimental-hydrate.js';
// eslint-disable-next-line @typescript-eslint/no-explicit-any
globalThis.litElementHydrateSupport = ({ LitElement, }) => {
    const observedAttributes = Object.getOwnPropertyDescriptor(Object.getPrototypeOf(LitElement), 'observedAttributes').get;
    // Add `defer-hydration` to observedAttributes
    Object.defineProperty(LitElement, 'observedAttributes', {
        get() {
            return [...observedAttributes.call(this), 'defer-hydration'];
        },
    });
    // Enable element when 'defer-hydration' attribute is removed by calling the
    // super.connectedCallback()
    const attributeChangedCallback = LitElement.prototype.attributeChangedCallback;
    LitElement.prototype.attributeChangedCallback = function (name, old, value) {
        if (name === 'defer-hydration' && value === null) {
            connectedCallback.call(this);
        }
        attributeChangedCallback.call(this, name, old, value);
    };
    // Override `connectedCallback` to capture whether we need hydration, and
    // defer `super.connectedCallback()` if the 'defer-hydration' attribute is set
    const connectedCallback = LitElement.prototype.connectedCallback;
    LitElement.prototype.connectedCallback = function () {
        // If the outer scope of this element has not yet been hydrated, wait until
        // 'defer-hydration' attribute has been removed to enable
        if (!this.hasAttribute('defer-hydration')) {
            connectedCallback.call(this);
        }
    };
    // If we've been server-side rendered, just return `this.shadowRoot`, don't
    // call the base implementation, which would also adopt styles (for now)
    const createRenderRoot = LitElement.prototype.createRenderRoot;
    LitElement.prototype.createRenderRoot = function () {
        if (this.shadowRoot) {
            this._$needsHydration = true;
            return this.shadowRoot;
        }
        else {
            return createRenderRoot.call(this);
        }
    };
    // Hydrate on first update when needed
    const update = Object.getPrototypeOf(LitElement.prototype).update;
    LitElement.prototype.update = function (changedProperties) {
        const value = this.render();
        // Since this is a patch, we can't call super.update(), so we capture
        // it off the proto chain and call it instead
        update.call(this, changedProperties);
        if (this._$needsHydration) {
            this._$needsHydration = false;
            hydrate(value, this.renderRoot, this.renderOptions);
        }
        else {
            render(value, this.renderRoot, this.renderOptions);
        }
    };
};
//# sourceMappingURL=experimental-hydrate-support.js.map