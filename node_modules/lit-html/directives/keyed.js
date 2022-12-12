import{nothing as r}from"../lit-html.js";import{directive as t,Directive as e}from"../directive.js";import{setCommittedValue as s}from"../directive-helpers.js";
/**
 * @license
 * Copyright 2021 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */const i=t(class extends e{constructor(){super(...arguments),this.key=r}render(r,t){return this.key=r,t}update(r,[t,e]){return t!==this.key&&(s(r),this.key=t),e}});export{i as keyed};
//# sourceMappingURL=keyed.js.map
