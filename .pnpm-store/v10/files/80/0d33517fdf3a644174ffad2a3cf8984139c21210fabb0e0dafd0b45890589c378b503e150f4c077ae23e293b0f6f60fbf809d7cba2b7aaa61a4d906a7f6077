/*
 *  Copyright (c) 2022 The adapter.js project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree.
 */
/* eslint-env node */
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.shimSelectAudioOutput = shimSelectAudioOutput;
function shimSelectAudioOutput(window) {
  // Polyfillying only makes sense when setSinkId is available
  // and the function is not already there.
  if (!('HTMLMediaElement' in window)) {
    return;
  }
  if (!('setSinkId' in window.HTMLMediaElement.prototype)) {
    return;
  }
  if (!(window.navigator && window.navigator.mediaDevices)) {
    return;
  }
  if (!window.navigator.mediaDevices.enumerateDevices) {
    return;
  }
  if (window.navigator.mediaDevices.selectAudioOutput) {
    return;
  }
  window.navigator.mediaDevices.selectAudioOutput = function () {
    return window.navigator.mediaDevices.enumerateDevices().then(function (devices) {
      return devices.filter(function (d) {
        return d.kind === 'audiooutput';
      });
    });
  };
}
