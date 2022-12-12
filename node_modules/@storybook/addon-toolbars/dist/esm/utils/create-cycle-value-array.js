import "core-js/modules/es.array.map.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.array.includes.js";
var disallowedCycleableItemTypes = ['reset'];
export var createCycleValueArray = function createCycleValueArray(items) {
  // Do not allow items in the cycle arrays that are conditional in placement
  var valueArray = items.filter(function (item) {
    return !disallowedCycleableItemTypes.includes(item.type);
  }).map(function (item) {
    return item.value;
  });
  return valueArray;
};