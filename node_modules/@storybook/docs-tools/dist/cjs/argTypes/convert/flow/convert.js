"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.convert = void 0;

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.replace.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.for-each.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.array.map.js");

/* eslint-disable no-case-declarations */
var isLiteral = function isLiteral(type) {
  return type.name === 'literal';
};

var toEnumOption = function toEnumOption(element) {
  return element.value.replace(/['|"]/g, '');
};

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

var convert = function convert(type) {
  var name = type.name,
      raw = type.raw;
  var base = {};
  if (typeof raw !== 'undefined') base.raw = raw;

  switch (type.name) {
    case 'literal':
      return Object.assign({}, base, {
        name: 'other',
        value: type.value
      });

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
      if (type.elements.every(isLiteral)) {
        return Object.assign({}, base, {
          name: 'enum',
          value: type.elements.map(toEnumOption)
        });
      }

      return Object.assign({}, base, {
        name: name,
        value: type.elements.map(convert)
      });

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

exports.convert = convert;