import SerialVirtualNode from '../base/virtual-node/serial-virtual-node';
import AbstractVirtualNode from '../base/virtual-node/abstract-virtual-node';
import * as helpers from '../reporters/helpers';
import {
  publishMetaData,
  finalizeRuleResult,
  aggregateResult,
  getRule
} from '../utils';

/**
 * Run a rule in a non-browser environment
 * @param {String} ruleId  Id of the rule
 * @param {VirtualNode} vNode  The virtual node to run the rule against
 * @param {Object} options  (optional) Set of options passed into rules or checks
 * @return {Object} axe results for the rule run
 */
function runVirtualRule(ruleId, vNode, options = {}) {
  // TODO: es-modules axe._audit
  // TODO: es-modules axe._selectorData
  options.reporter = options.reporter || axe._audit.reporter || 'v1';
  axe._selectorData = {};

  if (!(vNode instanceof AbstractVirtualNode)) {
    vNode = new SerialVirtualNode(vNode);
  }

  let rule = getRule(ruleId);

  if (!rule) {
    throw new Error('unknown rule `' + ruleId + '`');
  }

  // rule.prototype.gather calls axe.utils.isHidden which in turn calls
  // window.getComputedStyle if the rule excludes hidden elements. we
  // can avoid this call by forcing the rule to not exclude hidden
  // elements
  rule = Object.create(rule, { excludeHidden: { value: false } });

  const context = {
    initiator: true,
    include: [vNode]
  };

  const rawResults = rule.runSync(context, options);
  publishMetaData(rawResults);
  finalizeRuleResult(rawResults);
  const results = aggregateResult([rawResults]);

  results.violations.forEach(result =>
    result.nodes.forEach(nodeResult => {
      nodeResult.failureSummary = helpers.failureSummary(nodeResult);
    })
  );

  return {
    ...helpers.getEnvironmentData(),
    ...results,
    toolOptions: options
  };
}

export default runVirtualRule;
