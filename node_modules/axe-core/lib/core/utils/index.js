import { setDefaultFrameMessenger } from './frame-messenger';

/**
 * Namespace for utility helper methods.
 * @namespace utils
 * @memberof axe
 */
export { default as aggregate } from './aggregate';
export { default as aggregateChecks } from './aggregate-checks';
export { default as aggregateNodeResults } from './aggregate-node-results';
export { default as aggregateResult } from './aggregate-result';
export { default as areStylesSet } from './are-styles-set';
export { default as assert } from './assert';
export { default as checkHelper } from './check-helper';
export { default as clone } from './clone';
export { default as closest } from './closest';
export { default as collectResultsFromFrames } from './collect-results-from-frames';
export { default as contains } from './contains';
export { default as cssParser } from './css-parser';
export { default as deepMerge } from './deep-merge';
export { default as DqElement } from './dq-element';
export { default as matchesSelector } from './element-matches';
export { default as escapeSelector } from './escape-selector';
export { default as extendMetaData } from './extend-meta-data';
export { default as finalizeRuleResult } from './finalize-result';
export { default as findBy } from './find-by';
export { default as getFlattenedTree } from './get-flattened-tree';
export { default as getAllChecks } from './get-all-checks';
export { default as getBaseLang } from './get-base-lang';
export { default as getCheckMessage } from './get-check-message';
export { default as getCheckOption } from './get-check-option';
export { default as getFriendlyUriEnd } from './get-friendly-uri-end';
export { default as getNodeAttributes } from './get-node-attributes';
export { default as getNodeFromTree } from './get-node-from-tree';
export { default as getRootNode } from './get-root-node';
export { default as getRule } from './get-rule';
export { default as getScrollState } from './get-scroll-state';
export { default as getScroll } from './get-scroll';
export { default as getShadowSelector } from './get-shadow-selector';
export { default as getSelector, getSelectorData } from './get-selector';
export { default as getStyleSheetFactory } from './get-stylesheet-factory';
export { default as getXpath } from './get-xpath';
export { default as getAncestry } from './get-ancestry';
export { default as injectStyle } from './inject-style';
export { default as isHidden } from './is-hidden';
export { default as isHtmlElement } from './is-html-element';
export { default as isNodeInContext } from './is-node-in-context';
export { default as isShadowRoot } from './is-shadow-root';
export { default as isXHTML } from './is-xhtml';
export {
  default as matches,
  matchesExpression,
  convertSelector
} from './matches';
export { default as memoize } from './memoize';
export { default as mergeResults } from './merge-results';
export { default as nodeSorter } from './node-sorter';
export { default as parseCrossOriginStylesheet } from './parse-crossorigin-stylesheet';
export { default as parseSameOriginStylesheet } from './parse-sameorigin-stylesheet';
export { default as parseStylesheet } from './parse-stylesheet';
export { default as performanceTimer } from './performance-timer';
export { pollyfillElementsFromPoint } from './pollyfills';
export { default as preloadCssom } from './preload-cssom';
export { default as preloadMedia } from './preload-media';
export { default as preload, shouldPreload, getPreloadConfig } from './preload';
export { default as processMessage } from './process-message';
export { default as publishMetaData } from './publish-metadata';
export { default as querySelectorAllFilter } from './query-selector-all-filter';
export { default as querySelectorAll } from './query-selector-all';
export { default as queue } from './queue';
export { default as respondable } from './respondable';
export { default as ruleShouldRun } from './rule-should-run';
export { default as filterHtmlAttrs } from './filter-html-attrs';
export { default as select } from './select';
export { default as sendCommandToFrame } from './send-command-to-frame';
export { default as setScrollState } from './set-scroll-state';
export { default as toArray } from './to-array';
export { default as tokenList } from './token-list';
export { default as uniqueArray } from './unique-array';
export { default as uuid } from './uuid';
export { default as validInputTypes } from './valid-input-type';
export { default as isValidLang, validLangs } from './valid-langs';

// Setting up this private/temp namespace for the tests (which cannot yet `import/export` things).
// TODO: remove `_thisWillBeDeletedDoNotUse`
axe._thisWillBeDeletedDoNotUse = axe._thisWillBeDeletedDoNotUse || {};
axe._thisWillBeDeletedDoNotUse.utils = {
  setDefaultFrameMessenger
};
