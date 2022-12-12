import { isValidLang, getBaseLang } from '../../core/utils';
import { sanitize } from '../../commons/text';

function validLangEvaluate(node, options, virtualNode) {
  const invalid = [];
  options.attributes.forEach(langAttr => {
    const langVal = virtualNode.attr(langAttr);
    if (typeof langVal !== 'string') {
      return;
    }

    const baselangVal = getBaseLang(langVal);
    const invalidLang = options.value
      ? !options.value.map(getBaseLang).includes(baselangVal)
      : !isValidLang(baselangVal);

    // Edge sets lang to an empty string when xml:lang is set
    // so we need to ignore empty strings here
    if (
      (baselangVal !== '' && invalidLang) ||
      // whitespace only lang value is invalid
      (langVal !== '' && !sanitize(langVal))
    ) {
      invalid.push(langAttr + '="' + virtualNode.attr(langAttr) + '"');
    }
  });

  if (invalid.length) {
    this.data(invalid);
    return true;
  }

  return false;
}

export default validLangEvaluate;
