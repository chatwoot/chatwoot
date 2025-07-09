import{render as t}from"lit-html";import{hydrate as s}from"lit-html/experimental-hydrate.js";import{HYDRATE_INTERNALS_ATTR_PREFIX as i}from"@lit-labs/ssr-dom-shim";
/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
globalThis.litElementHydrateSupport=({LitElement:e})=>{const r=Object.getOwnPropertyDescriptor(Object.getPrototypeOf(e),"observedAttributes").get;Object.defineProperty(e,"observedAttributes",{get(){return[...r.call(this),"defer-hydration"]}});const o=e.prototype.attributeChangedCallback;e.prototype.attributeChangedCallback=function(t,s,i){"defer-hydration"===t&&null===i&&h.call(this),o.call(this,t,s,i)};const h=e.prototype.connectedCallback;e.prototype.connectedCallback=function(){this.hasAttribute("defer-hydration")||h.call(this)};const n=e.prototype.createRenderRoot;e.prototype.createRenderRoot=function(){return this.shadowRoot?(this._$AG=!0,this.shadowRoot):n.call(this)};const l=Object.getPrototypeOf(e.prototype).update;e.prototype.update=function(e){const r=this.render();if(l.call(this,e),this._$AG){this._$AG=!1;for(let t=0;t<this.attributes.length;t++){const s=this.attributes[t];if(s.name.startsWith(i)){const t=s.name.slice(i.length);this.removeAttribute(t),this.removeAttribute(s.name)}}s(r,this.renderRoot,this.renderOptions)}else t(r,this.renderRoot,this.renderOptions)}},console.warn("Import from `lit-element/experimental-hydrate-support.js` is deprecated.Import `@lit-labs/ssr-client/lit-element-hydrate-support.js` instead.");
//# sourceMappingURL=experimental-hydrate-support.js.map
