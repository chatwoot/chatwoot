/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 */
'use strict';

var muxjs = {
  codecs: require('./codecs'),
  mp4: require('./mp4'),
  flv: require('./flv'),
  mp2t: require('./m2ts'),
  partial: require('./partial')
}; // include all the tools when the full library is required

muxjs.mp4.tools = require('./tools/mp4-inspector');
muxjs.flv.tools = require('./tools/flv-inspector');
muxjs.mp2t.tools = require('./tools/ts-inspector');
module.exports = muxjs;