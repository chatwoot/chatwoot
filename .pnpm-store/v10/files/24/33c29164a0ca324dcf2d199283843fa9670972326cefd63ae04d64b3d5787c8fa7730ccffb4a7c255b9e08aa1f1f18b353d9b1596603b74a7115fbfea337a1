import{noChange as t}from"../lit-html.js";import{isPrimitive as s}from"../directive-helpers.js";import{AsyncDirective as i}from"../async-directive.js";import{PseudoWeakRef as r,Pauser as e}from"./private-async-helpers.js";import{directive as o}from"../directive.js";
/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */const n=t=>!s(t)&&"function"==typeof t.then,h=1073741823;class c extends i{constructor(){super(...arguments),this._$C_t=h,this._$Cwt=[],this._$Cq=new r(this),this._$CK=new e}render(...s){var i;return null!==(i=s.find((t=>!n(t))))&&void 0!==i?i:t}update(s,i){const r=this._$Cwt;let e=r.length;this._$Cwt=i;const o=this._$Cq,c=this._$CK;this.isConnected||this.disconnected();for(let t=0;t<i.length&&!(t>this._$C_t);t++){const s=i[t];if(!n(s))return this._$C_t=t,s;t<e&&s===r[t]||(this._$C_t=h,e=0,Promise.resolve(s).then((async t=>{for(;c.get();)await c.get();const i=o.deref();if(void 0!==i){const r=i._$Cwt.indexOf(s);r>-1&&r<i._$C_t&&(i._$C_t=r,i.setValue(t))}})))}return t}disconnected(){this._$Cq.disconnect(),this._$CK.pause()}reconnected(){this._$Cq.reconnect(this),this._$CK.resume()}}const m=o(c);export{c as UntilDirective,m as until};
//# sourceMappingURL=until.js.map
