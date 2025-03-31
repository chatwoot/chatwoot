/**
 * Tagged template function which returns paramaterized representation of the message
 * For example: parameterize`This is a log statement with ${x} and ${y} params`, would return:
 * "__sentry_template_string__": 'This is a log statement with %s and %s params',
 * "__sentry_template_values__": ['first', 'second']
 * @param strings An array of string values splitted between expressions
 * @param values Expressions extracted from template string
 * @returns String with template information in __sentry_template_string__ and __sentry_template_values__ properties
 */
function parameterize(strings, ...values) {
  const formatted = new String(String.raw(strings, ...values)) ;
  formatted.__sentry_template_string__ = strings.join('\x00').replace(/%/g, '%%').replace(/\0/g, '%s');
  formatted.__sentry_template_values__ = values;
  return formatted;
}

export { parameterize };
//# sourceMappingURL=parameterize.js.map
