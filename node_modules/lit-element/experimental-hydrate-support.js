import{render as t}from"lit-html";import{hydrate as i}from"lit-html/experimental-hydrate.js";
/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
globalThis.litElementHydrateSupport=({LitElement:s})=>{const e=Object.getOwnPropertyDescriptor(Object.getPrototypeOf(s),"observedAttributes").get;Object.defineProperty(s,"observedAttributes",{get(){return[...e.call(this),"defer-hydration"]}});const h=s.prototype.attributeChangedCallback;s.prototype.attributeChangedCallback=function(t,i,s){"defer-hydration"===t&&null===s&&n.call(this),h.call(this,t,i,s)};const n=s.prototype.connectedCallback;s.prototype.connectedCallback=function(){this.hasAttribute("defer-hydration")||n.call(this)};const o=s.prototype.createRenderRoot;s.prototype.createRenderRoot=function(){return this.shadowRoot?(this._$AG=!0,this.shadowRoot):o.call(this)};const r=Object.getPrototypeOf(s.prototype).update;s.prototype.update=function(s){const e=this.render();r.call(this,s),this._$AG?(this._$AG=!1,i(e,this.renderRoot,this.renderOptions)):t(e,this.renderRoot,this.renderOptions)}};
//# sourceMappingURL=experimental-hydrate-support.js.map
