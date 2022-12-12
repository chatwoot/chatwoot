"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _telejson = require("telejson");

/* eslint-disable no-underscore-dangle */

/* eslint-disable func-names */
// setting up the store, overriding set and get to use telejson
var _default = function _default(_) {
  _.fn('set', function (key, data) {
    return _.set(this._area, this._in(key), (0, _telejson.stringify)(data, {
      maxDepth: 50
    }));
  });

  _.fn('get', function (key, alt) {
    var value = _.get(this._area, this._in(key));

    return value !== null ? (0, _telejson.parse)(value) : alt || value;
  });
};

exports.default = _default;