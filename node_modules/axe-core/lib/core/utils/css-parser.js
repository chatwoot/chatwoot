import { CssSelectorParser } from 'css-selector-parser';

const parser = new CssSelectorParser();
parser.registerSelectorPseudos('not');
parser.registerSelectorPseudos('is');
parser.registerNestingOperators('>');
parser.registerAttrEqualityMods('^', '$', '*', '~');

export default parser;
