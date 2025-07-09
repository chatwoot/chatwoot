/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 */
'use strict';

var TagList = function TagList() {
  var self = this;
  this.list = [];

  this.push = function (tag) {
    this.list.push({
      bytes: tag.bytes,
      dts: tag.dts,
      pts: tag.pts,
      keyFrame: tag.keyFrame,
      metaDataTag: tag.metaDataTag
    });
  };

  Object.defineProperty(this, 'length', {
    get: function get() {
      return self.list.length;
    }
  });
};

module.exports = TagList;