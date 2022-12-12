import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.array.map.js";

/* eslint-disable no-case-declarations */
var convertSig = function convertSig(type) {
  switch (type.type) {
    case 'function':
      return {
        name: 'function'
      };

    case 'object':
      var values = {};
      type.signature.properties.forEach(function (prop) {
        values[prop.key] = convert(prop.value);
      });
      return {
        name: 'object',
        value: values
      };

    default:
      throw new Error("Unknown: ".concat(type));
  }
};

export var convert = function convert(type) {
  var name = type.name,
      raw = type.raw;
  var base = {};
  if (typeof raw !== 'undefined') base.raw = raw;

  switch (type.name) {
    case 'string':
    case 'number':
    case 'symbol':
    case 'boolean':
      {
        return Object.assign({}, base, {
          name: name
        });
      }

    case 'Array':
      {
        return Object.assign({}, base, {
          name: 'array',
          value: type.elements.map(convert)
        });
      }

    case 'signature':
      return Object.assign({}, base, convertSig(type));

    case 'union':
    case 'intersection':
      return Object.assign({}, base, {
        name: name,
        value: type.elements.map(convert)
      });

    default:
      return Object.assign({}, base, {
        name: 'other',
        value: name
      });
  }
};