import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.number.is-nan.js";
import "core-js/modules/es.number.constructor.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.split.js";
import "core-js/modules/es.array.concat.js";

/* eslint-disable no-case-declarations */
import mapValues from 'lodash/mapValues';
import { includesQuotes, trimQuotes } from '../utils';
var SIGNATURE_REGEXP = /^\(.*\) => /;
export var convert = function convert(type) {
  var name = type.name,
      raw = type.raw,
      computed = type.computed,
      value = type.value;
  var base = {};
  if (typeof raw !== 'undefined') base.raw = raw;

  switch (name) {
    case 'enum':
      {
        var _values = computed ? value : value.map(function (v) {
          var trimmedValue = trimQuotes(v.value);
          return includesQuotes(v.value) || Number.isNaN(Number(trimmedValue)) ? trimmedValue : Number(trimmedValue);
        });

        return Object.assign({}, base, {
          name: name,
          value: _values
        });
      }

    case 'string':
    case 'number':
    case 'symbol':
      return Object.assign({}, base, {
        name: name
      });

    case 'func':
      return Object.assign({}, base, {
        name: 'function'
      });

    case 'bool':
    case 'boolean':
      return Object.assign({}, base, {
        name: 'boolean'
      });

    case 'arrayOf':
    case 'array':
      return Object.assign({}, base, {
        name: 'array',
        value: value && convert(value)
      });

    case 'object':
      return Object.assign({}, base, {
        name: name
      });

    case 'objectOf':
      return Object.assign({}, base, {
        name: name,
        value: convert(value)
      });

    case 'shape':
    case 'exact':
      var values = mapValues(value, function (field) {
        return convert(field);
      });
      return Object.assign({}, base, {
        name: 'object',
        value: values
      });

    case 'union':
      return Object.assign({}, base, {
        name: 'union',
        value: value.map(function (v) {
          return convert(v);
        })
      });

    case 'instanceOf':
    case 'element':
    case 'elementType':
    default:
      {
        if ((name === null || name === void 0 ? void 0 : name.indexOf('|')) > 0) {
          // react-docgen-typescript-plugin doesn't always produce enum-like unions
          // (like if a user has turned off shouldExtractValuesFromUnion) so here we
          // try to recover and construct one.
          try {
            var literalValues = name.split('|').map(function (v) {
              return JSON.parse(v);
            });
            return Object.assign({}, base, {
              name: 'enum',
              value: literalValues
            });
          } catch (err) {// fall through
          }
        }

        var otherVal = value ? "".concat(name, "(").concat(value, ")") : name;
        var otherName = SIGNATURE_REGEXP.test(name) ? 'function' : 'other';
        return Object.assign({}, base, {
          name: otherName,
          value: otherVal
        });
      }
  }
};