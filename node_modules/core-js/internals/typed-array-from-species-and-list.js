var aTypedArrayConstructor = require('../internals/array-buffer-view-core').aTypedArrayConstructor;
var speciesConstructor = require('../internals/species-constructor');

module.exports = function (instance, list) {
  var C = speciesConstructor(instance, instance.constructor);
  var index = 0;
  var length = list.length;
  var result = new (aTypedArrayConstructor(C))(length);
  while (length > index) result[index] = list[index++];
  return result;
};
