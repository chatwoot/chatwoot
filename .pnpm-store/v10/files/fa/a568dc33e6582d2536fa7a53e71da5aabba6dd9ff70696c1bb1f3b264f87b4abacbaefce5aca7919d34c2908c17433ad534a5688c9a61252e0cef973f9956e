"use strict";

/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 */
var highPrefix = [33, 16, 5, 32, 164, 27];
var lowPrefix = [33, 65, 108, 84, 1, 2, 4, 8, 168, 2, 4, 8, 17, 191, 252];

var zeroFill = function zeroFill(count) {
  var a = [];

  while (count--) {
    a.push(0);
  }

  return a;
};

var makeTable = function makeTable(metaTable) {
  return Object.keys(metaTable).reduce(function (obj, key) {
    obj[key] = new Uint8Array(metaTable[key].reduce(function (arr, part) {
      return arr.concat(part);
    }, []));
    return obj;
  }, {});
};

var silence;

module.exports = function () {
  if (!silence) {
    // Frames-of-silence to use for filling in missing AAC frames
    var coneOfSilence = {
      96000: [highPrefix, [227, 64], zeroFill(154), [56]],
      88200: [highPrefix, [231], zeroFill(170), [56]],
      64000: [highPrefix, [248, 192], zeroFill(240), [56]],
      48000: [highPrefix, [255, 192], zeroFill(268), [55, 148, 128], zeroFill(54), [112]],
      44100: [highPrefix, [255, 192], zeroFill(268), [55, 163, 128], zeroFill(84), [112]],
      32000: [highPrefix, [255, 192], zeroFill(268), [55, 234], zeroFill(226), [112]],
      24000: [highPrefix, [255, 192], zeroFill(268), [55, 255, 128], zeroFill(268), [111, 112], zeroFill(126), [224]],
      16000: [highPrefix, [255, 192], zeroFill(268), [55, 255, 128], zeroFill(268), [111, 255], zeroFill(269), [223, 108], zeroFill(195), [1, 192]],
      12000: [lowPrefix, zeroFill(268), [3, 127, 248], zeroFill(268), [6, 255, 240], zeroFill(268), [13, 255, 224], zeroFill(268), [27, 253, 128], zeroFill(259), [56]],
      11025: [lowPrefix, zeroFill(268), [3, 127, 248], zeroFill(268), [6, 255, 240], zeroFill(268), [13, 255, 224], zeroFill(268), [27, 255, 192], zeroFill(268), [55, 175, 128], zeroFill(108), [112]],
      8000: [lowPrefix, zeroFill(268), [3, 121, 16], zeroFill(47), [7]]
    };
    silence = makeTable(coneOfSilence);
  }

  return silence;
};