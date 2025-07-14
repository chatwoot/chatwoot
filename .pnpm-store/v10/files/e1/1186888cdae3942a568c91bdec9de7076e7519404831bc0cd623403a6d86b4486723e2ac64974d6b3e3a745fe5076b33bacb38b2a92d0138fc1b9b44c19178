import{noChange as t}from"../lit-html.js";import{AsyncDirective as i}from"../async-directive.js";import{PseudoWeakRef as s,Pauser as r,forAwaitOf as e}from"./private-async-helpers.js";import{directive as n}from"../directive.js";
/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */class o extends i{constructor(){super(...arguments),this._$Cq=new s(this),this._$CK=new r}render(i,s){return t}update(i,[s,r]){if(this.isConnected||this.disconnected(),s===this._$CX)return;this._$CX=s;let n=0;const{_$Cq:o,_$CK:h}=this;return e(s,(async t=>{for(;h.get();)await h.get();const i=o.deref();if(void 0!==i){if(i._$CX!==s)return!1;void 0!==r&&(t=r(t,n)),i.commitValue(t,n),n++}return!0})),t}commitValue(t,i){this.setValue(t)}disconnected(){this._$Cq.disconnect(),this._$CK.pause()}reconnected(){this._$Cq.reconnect(this),this._$CK.resume()}}const h=n(o);export{o as AsyncReplaceDirective,h as asyncReplace};
//# sourceMappingURL=async-replace.js.map
