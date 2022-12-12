/* eslint-disable no-case-declarations */
const convertSig = type => {
  switch (type.type) {
    case 'function':
      return {
        name: 'function'
      };

    case 'object':
      const values = {};
      type.signature.properties.forEach(prop => {
        values[prop.key] = convert(prop.value);
      });
      return {
        name: 'object',
        value: values
      };

    default:
      throw new Error(`Unknown: ${type}`);
  }
};

export const convert = type => {
  const {
    name,
    raw
  } = type;
  const base = {};
  if (typeof raw !== 'undefined') base.raw = raw;

  switch (type.name) {
    case 'string':
    case 'number':
    case 'symbol':
    case 'boolean':
      {
        return Object.assign({}, base, {
          name
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
        name,
        value: type.elements.map(convert)
      });

    default:
      return Object.assign({}, base, {
        name: 'other',
        value: name
      });
  }
};