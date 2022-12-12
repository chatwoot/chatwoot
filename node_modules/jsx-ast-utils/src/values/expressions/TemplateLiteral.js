function sortStarts(a, b) {
  return (a.range ? a.range[0] : a.start) - (b.range ? b.range[0] : b.start);
}

/**
 * Returns the string value of a template literal object.
 * Tries to build it as best as it can based on the passed
 * prop. For instance `This is a ${prop}` will return 'This is a {prop}'.
 *
 * If the template literal builds to undefined (`${undefined}`), then
 * this should return "undefined".
 */
export default function extractValueFromTemplateLiteral(value) {
  const {
    quasis,
    expressions,
  } = value;
  const partitions = quasis.concat(expressions);

  return partitions.sort(sortStarts).reduce((raw, part) => {
    const {
      type,
    } = part;
    if (type === 'TemplateElement') {
      return raw + part.value.raw;
    }

    if (type === 'Identifier') {
      return part.name === 'undefined' ? `${raw}${part.name}` : `${raw}{${part.name}}`;
    }

    if (type.indexOf('Expression') > -1) {
      return `${raw}{${type}}`;
    }

    return raw;
  }, '');
}
