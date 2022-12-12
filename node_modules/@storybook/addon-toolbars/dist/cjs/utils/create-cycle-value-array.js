"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createCycleValueArray = void 0;

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.array.includes.js");

var disallowedCycleableItemTypes = ['reset'];

var createCycleValueArray = function createCycleValueArray(items) {
  // Do not allow items in the cycle arrays that are conditional in placement
  var valueArray = items.filter(function (item) {
    return !disallowedCycleableItemTypes.includes(item.type);
  }).map(function (item) {
    return item.value;
  });
  return valueArray;
};

exports.createCycleValueArray = createCycleValueArray;