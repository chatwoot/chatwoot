import{noChange as t}from"../lit-html.js";import{directive as i}from"../directive.js";import{AsyncDirective as s}from"../async-directive.js";import{PseudoWeakRef as r,Pauser as e,forAwaitOf as n}from"./private-async-helpers.js";
/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */class o extends s{constructor(){super(...arguments),this._$CG=new r(this),this._$CK=new e}render(i,s){return t}update(i,[s,r]){if(this.isConnected||this.disconnected(),s===this._$CJ)return;this._$CJ=s;let e=0;const{_$CG:o,_$CK:h}=this;return n(s,(async t=>{for(;h.get();)await h.get();const i=o.deref();if(void 0!==i){if(i._$CJ!==s)return!1;void 0!==r&&(t=r(t,e)),i.commitValue(t,e),e++}return!0})),t}commitValue(t,i){this.setValue(t)}disconnected(){this._$CG.disconnect(),this._$CK.pause()}reconnected(){this._$CG.reconnect(this),this._$CK.resume()}}const h=i(o);export{o as AsyncReplaceDirective,h as asyncReplace};
//# sourceMappingURL=async-replace.js.map
