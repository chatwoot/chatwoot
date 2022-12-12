import{nothing as t}from"../lit-html.js";import{AsyncDirective as i}from"../async-directive.js";import{directive as s}from"../directive.js";
/**
 * @license
 * Copyright 2020 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */const e=()=>new o;class o{}const h=new WeakMap,n=s(class extends i{render(i){return t}update(i,[s]){var e;const o=s!==this.U;return o&&void 0!==this.U&&this.ot(void 0),(o||this.rt!==this.lt)&&(this.U=s,this.ht=null===(e=i.options)||void 0===e?void 0:e.host,this.ot(this.lt=i.element)),t}ot(t){"function"==typeof this.U?(void 0!==h.get(this.U)&&this.U.call(this.ht,void 0),h.set(this.U,t),void 0!==t&&this.U.call(this.ht,t)):this.U.value=t}get rt(){var t;return"function"==typeof this.U?h.get(this.U):null===(t=this.U)||void 0===t?void 0:t.value}disconnected(){this.rt===this.lt&&this.ot(void 0)}reconnected(){this.ot(this.lt)}});export{e as createRef,n as ref};
//# sourceMappingURL=ref.js.map
