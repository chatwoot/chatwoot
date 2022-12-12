import { autocomplete, sanitize } from '../../commons/text';
import { validInputTypes } from '../../core/utils';

function autocompleteAppropriateEvaluate(node, options, virtualNode) {
  // Select and textarea is always allowed
  if (virtualNode.props.nodeName !== 'input') {
    return true;
  }

  const number = ['text', 'search', 'number', 'tel'];
  const url = ['text', 'search', 'url'];
  const allowedTypesMap = {
    bday: ['text', 'search', 'date'],
    email: ['text', 'search', 'email'],
    'street-address': ['text'], // Issue: https://github.com/dequelabs/axe-core/issues/1161
    tel: ['text', 'search', 'tel'],
    'tel-country-code': ['text', 'search', 'tel'],
    'tel-national': ['text', 'search', 'tel'],
    'tel-area-code': ['text', 'search', 'tel'],
    'tel-local': ['text', 'search', 'tel'],
    'tel-local-prefix': ['text', 'search', 'tel'],
    'tel-local-suffix': ['text', 'search', 'tel'],
    'tel-extension': ['text', 'search', 'tel'],
    'cc-number': number,
    'cc-exp': ['text', 'search', 'month', 'tel'],
    'cc-exp-month': number,
    'cc-exp-year': number,
    'cc-csc': number,
    'transaction-amount': number,
    'bday-day': number,
    'bday-month': number,
    'bday-year': number,
    'new-password': ['text', 'search', 'password'],
    'current-password': ['text', 'search', 'password'],
    url: url,
    photo: url,
    impp: url
  };

  if (typeof options === 'object') {
    // Merge in options
    Object.keys(options).forEach(key => {
      if (!allowedTypesMap[key]) {
        allowedTypesMap[key] = [];
      }
      allowedTypesMap[key] = allowedTypesMap[key].concat(options[key]);
    });
  }

  const autocompleteAttr = virtualNode.attr('autocomplete');
  const autocompleteTerms = autocompleteAttr
    .split(/\s+/g)
    .map(term => term.toLowerCase());

  const purposeTerm = autocompleteTerms[autocompleteTerms.length - 1];
  if (autocomplete.stateTerms.includes(purposeTerm)) {
    return true;
  }

  const allowedTypes = allowedTypesMap[purposeTerm];

  /**
   * Note:
   * Inconsistent response for `node.type` across browsers, hence resolving and sanitizing using getAttribute
   * Example:
   * Firefox returns `node.type` as `text` for `type='month'`
   *
   * Reference HTML Spec - https://html.spec.whatwg.org/multipage/input.html#the-input-element to filter allowed values for `type`
   * and sanitize (https://html.spec.whatwg.org/multipage/input.html#value-sanitization-algorithm)
   */
  let type = virtualNode.hasAttr('type')
    ? sanitize(virtualNode.attr('type')).toLowerCase()
    : 'text';
  type = validInputTypes().includes(type) ? type : 'text';

  if (typeof allowedTypes === 'undefined') {
    return type === 'text';
  }

  return allowedTypes.includes(type);
}

export default autocompleteAppropriateEvaluate;
