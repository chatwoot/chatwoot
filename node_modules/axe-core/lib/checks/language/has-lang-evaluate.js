import { isXHTML } from '../../core/utils';

function hasValue(value) {
  return (value || '').trim() !== '';
}

function hasLangEvaluate(node, options, virtualNode) {
  // special case when xml:lang has a value and lang does not
  // but the document is not XHTML
  const xhtml = typeof document !== 'undefined' ? isXHTML(document) : false;

  if (
    options.attributes.includes('xml:lang') &&
    options.attributes.includes('lang') &&
    hasValue(virtualNode.attr('xml:lang')) &&
    !hasValue(virtualNode.attr('lang')) &&
    !xhtml
  ) {
    this.data({
      messageKey: 'noXHTML'
    });
    return false;
  }

  const hasLang = options.attributes.some(name => {
    return hasValue(virtualNode.attr(name));
  });

  if (!hasLang) {
    this.data({
      messageKey: 'noLang'
    });
    return false;
  }

  return true;
}

export default hasLangEvaluate;
