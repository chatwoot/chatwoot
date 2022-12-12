import { getBaseLang } from '../../core/utils';

function xmlLangMismatchEvaluate(node, options, vNode) {
  const primaryLangValue = getBaseLang(vNode.attr('lang'));
  const primaryXmlLangValue = getBaseLang(vNode.attr('xml:lang'));

  return primaryLangValue === primaryXmlLangValue;
}

export default xmlLangMismatchEvaluate;
