'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var postcss = require('postcss');
var postcss__default = _interopDefault(postcss);

function shiftNodesBeforeParent(node) {
  const parent = node.parent;
  const index = parent.index(node); // conditionally move previous siblings into a clone of the parent

  if (index) {
    parent.cloneBefore().removeAll().append(parent.nodes.slice(0, index));
  } // move the current node before the parent (and after the conditional clone)


  parent.before(node);
  return parent;
}

function cleanupParent(parent) {
  if (!parent.nodes.length) {
    parent.remove();
  }
}

// a valid selector is an ampersand followed by a non-word character or nothing
var validSelector = /&(?:[^\w-|]|$)/;
const replaceable = /&/g;

function mergeSelectors(fromSelectors, toSelectors) {
  return fromSelectors.reduce((selectors, fromSelector) => selectors.concat(toSelectors.map(toSelector => toSelector.replace(replaceable, fromSelector))), []);
}

function transformRuleWithinRule(node) {
  // move previous siblings and the node to before the parent
  const parent = shiftNodesBeforeParent(node); // update the selectors of the node to be merged with the parent

  node.selectors = mergeSelectors(parent.selectors, node.selectors); // merge similar rules back together
  // eslint-disable-next-line no-extra-parens

  const areSameRule = node.type === 'rule' && parent.type === 'rule' && node.selector === parent.selector || node.type === 'atrule' && parent.type === 'atrule' && node.params === parent.params;

  if (areSameRule) {
    node.append(...parent.nodes);
  } // conditionally cleanup an empty parent rule


  cleanupParent(parent);
}
const isRuleWithinRule = node => node.type === 'rule' && Object(node.parent).type === 'rule' && node.selectors.every(selector => selector.trim().lastIndexOf('&') === 0 && validSelector.test(selector));

const comma = postcss.list.comma;
function transformNestRuleWithinRule(node) {
  // move previous siblings and the node to before the parent
  const parent = shiftNodesBeforeParent(node); // clone the parent as a new rule with children appended to it

  const rule = parent.clone().removeAll().append(node.nodes); // replace the node with the new rule

  node.replaceWith(rule); // update the selectors of the node to be merged with the parent

  rule.selectors = mergeSelectors(parent.selectors, comma(node.params)); // conditionally cleanup an empty parent rule

  cleanupParent(parent); // walk the children of the new rule

  walk(rule);
}
const isNestRuleWithinRule = node => node.type === 'atrule' && node.name === 'nest' && Object(node.parent).type === 'rule' && comma(node.params).every(selector => selector.split('&').length === 2 && validSelector.test(selector));

var validAtrules = ['document', 'media', 'supports'];

/*
 * DEPRECATED: In v7.0.0 these features will be removed as they are not part of
 * the nesting proposal.
 */

function atruleWithinRule(node) {
  // move previous siblings and the node to before the parent
  const parent = shiftNodesBeforeParent(node); // clone the parent as a new rule with children appended to it

  const rule = parent.clone().removeAll().append(node.nodes); // append the new rule to the node

  node.append(rule); // conditionally cleanup an empty parent rule

  cleanupParent(parent); // walk the children of the new rule

  walk(rule);
}
const isAtruleWithinRule = node => node.type === 'atrule' && validAtrules.indexOf(node.name) !== -1 && Object(node.parent).type === 'rule';

const comma$1 = postcss.list.comma;
function mergeParams(fromParams, toParams) {
  return comma$1(fromParams).map(params1 => comma$1(toParams).map(params2 => `${params1} and ${params2}`).join(', ')).join(', ');
}

/*
 * DEPRECATED: In v7.0.0 these features will be removed as they are not part of
 * the nesting proposal.
 */

function transformAtruleWithinAtrule(node) {
  // move previous siblings and the node to before the parent
  const parent = shiftNodesBeforeParent(node); // update the params of the node to be merged with the parent

  node.params = mergeParams(parent.params, node.params); // conditionally cleanup an empty parent rule

  cleanupParent(parent);
}
const isAtruleWithinAtrule = node => node.type === 'atrule' && validAtrules.indexOf(node.name) !== -1 && Object(node.parent).type === 'atrule' && node.name === node.parent.name;

function walk(node) {
  node.nodes.slice(0).forEach(child => {
    if (child.parent === node) {
      if (isRuleWithinRule(child)) {
        transformRuleWithinRule(child);
      } else if (isNestRuleWithinRule(child)) {
        transformNestRuleWithinRule(child);
      } else if (isAtruleWithinRule(child)) {
        atruleWithinRule(child);
      } else if (isAtruleWithinAtrule(child)) {
        transformAtruleWithinAtrule(child);
      }

      if (Object(child.nodes).length) {
        walk(child);
      }
    }
  });
}

var index = postcss__default.plugin('postcss-nesting', () => walk);

module.exports = index;
//# sourceMappingURL=index.cjs.js.map
