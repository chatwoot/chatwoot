import{noChange as t}from"../lit-html.js";import{directive as s}from"../directive.js";import{isPrimitive as i}from"../directive-helpers.js";import{AsyncDirective as r}from"../async-directive.js";import{PseudoWeakRef as e,Pauser as o}from"./private-async-helpers.js";
/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */const n=t=>!i(t)&&"function"==typeof t.then;class h extends r{constructor(){super(...arguments),this._$Cft=1073741823,this._$Cwt=[],this._$CG=new e(this),this._$CK=new o}render(...s){var i;return null!==(i=s.find((t=>!n(t))))&&void 0!==i?i:t}update(s,i){const r=this._$Cwt;let e=r.length;this._$Cwt=i;const o=this._$CG,h=this._$CK;this.isConnected||this.disconnected();for(let t=0;t<i.length&&!(t>this._$Cft);t++){const s=i[t];if(!n(s))return this._$Cft=t,s;t<e&&s===r[t]||(this._$Cft=1073741823,e=0,Promise.resolve(s).then((async t=>{for(;h.get();)await h.get();const i=o.deref();if(void 0!==i){const r=i._$Cwt.indexOf(s);r>-1&&r<i._$Cft&&(i._$Cft=r,i.setValue(t))}})))}return t}disconnected(){this._$CG.disconnect(),this._$CK.pause()}reconnected(){this._$CG.reconnect(this),this._$CK.resume()}}const c=s(h);export{h as UntilDirective,c as until};
//# sourceMappingURL=until.js.map
