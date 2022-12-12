import{noChange as r,nothing as e}from"../lit-html.js";import{directive as i,Directive as t,PartType as n}from"../directive.js";import{isSingleExpression as o,setCommittedValue as s}from"../directive-helpers.js";
/**
 * @license
 * Copyright 2020 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */const l=i(class extends t{constructor(r){if(super(r),r.type!==n.PROPERTY&&r.type!==n.ATTRIBUTE&&r.type!==n.BOOLEAN_ATTRIBUTE)throw Error("The `live` directive is not allowed on child or event bindings");if(!o(r))throw Error("`live` bindings can only contain a single expression")}render(r){return r}update(i,[t]){if(t===r||t===e)return t;const o=i.element,l=i.name;if(i.type===n.PROPERTY){if(t===o[l])return r}else if(i.type===n.BOOLEAN_ATTRIBUTE){if(!!t===o.hasAttribute(l))return r}else if(i.type===n.ATTRIBUTE&&o.getAttribute(l)===t+"")return r;return s(i),t}});export{l as live};
//# sourceMappingURL=live.js.map
