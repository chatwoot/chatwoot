/* eslint-disable no-case-declarations */
import mapValues from 'lodash/mapValues';
import { includesQuotes, trimQuotes } from '../utils';
const SIGNATURE_REGEXP = /^\(.*\) => /;
export const convert = type => {
  const {
    name,
    raw,
    computed,
    value
  } = type;
  const base = {};
  if (typeof raw !== 'undefined') base.raw = raw;

  switch (name) {
    case 'enum':
      {
        const values = computed ? value : value.map(v => {
          const trimmedValue = trimQuotes(v.value);
          return includesQuotes(v.value) || Number.isNaN(Number(trimmedValue)) ? trimmedValue : Number(trimmedValue);
        });
        return Object.assign({}, base, {
          name,
          value: values
        });
      }

    case 'string':
    case 'number':
    case 'symbol':
      return Object.assign({}, base, {
        name
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
        name
      });

    case 'objectOf':
      return Object.assign({}, base, {
        name,
        value: convert(value)
      });

    case 'shape':
    case 'exact':
      const values = mapValues(value, field => convert(field));
      return Object.assign({}, base, {
        name: 'object',
        value: values
      });

    case 'union':
      return Object.assign({}, base, {
        name: 'union',
        value: value.map(v => convert(v))
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
            const literalValues = name.split('|').map(v => JSON.parse(v));
            return Object.assign({}, base, {
              name: 'enum',
              value: literalValues
            });
          } catch (err) {// fall through
          }
        }

        const otherVal = value ? `${name}(${value})` : name;
        const otherName = SIGNATURE_REGEXP.test(name) ? 'function' : 'other';
        return Object.assign({}, base, {
          name: otherName,
          value: otherVal
        });
      }
  }
};