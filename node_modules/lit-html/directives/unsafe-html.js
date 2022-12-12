import{nothing as t,noChange as i}from"../lit-html.js";import{Directive as r,PartType as s,directive as n}from"../directive.js";
/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */class e extends r{constructor(i){if(super(i),this.it=t,i.type!==s.CHILD)throw Error(this.constructor.directiveName+"() can only be used in child bindings")}render(r){if(r===t||null==r)return this.vt=void 0,this.it=r;if(r===i)return r;if("string"!=typeof r)throw Error(this.constructor.directiveName+"() called with a non-string value");if(r===this.it)return this.vt;this.it=r;const s=[r];return s.raw=s,this.vt={_$litType$:this.constructor.resultType,strings:s,values:[]}}}e.directiveName="unsafeHTML",e.resultType=1;const o=n(e);export{e as UnsafeHTMLDirective,o as unsafeHTML};
//# sourceMappingURL=unsafe-html.js.map
