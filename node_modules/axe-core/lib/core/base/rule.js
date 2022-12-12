/*global SupportError */
import { createExecutionContext } from './check';
import RuleResult from './rule-result';
import {
  performanceTimer,
  getAllChecks,
  getCheckOption,
  queue,
  DqElement,
  select,
  isHidden,
  assert
} from '../utils';
import constants from '../constants';
import log from '../log';

function Rule(spec, parentAudit) {
  this._audit = parentAudit;

  /**
   * The code, or string ID of the rule
   * @type {String}
   */
  this.id = spec.id;

  /**
   * Selector that this rule applies to
   * @type {String}
   */
  this.selector = spec.selector || '*';

  /**
   * Impact of the rule (optional)
   * @type {"minor" | "moderate" | "serious" | "critical"}
   */
  if (spec.impact) {
    assert(
      constants.impact.includes(spec.impact),
      `Impact ${spec.impact} is not a valid impact`
    );
    this.impact = spec.impact;
  }

  /**
   * Whether to exclude hiddden elements form analysis.  Defaults to true.
   * @type {Boolean}
   */
  this.excludeHidden =
    typeof spec.excludeHidden === 'boolean' ? spec.excludeHidden : true;

  /**
   * Flag to enable or disable rule
   * @type {Boolean}
   */
  this.enabled = typeof spec.enabled === 'boolean' ? spec.enabled : true;

  /**
   * Denotes if the rule should be run if Context is not an entire page AND whether
   * the Rule should be satisified regardless of Node
   * @type {Boolean}
   */
  this.pageLevel = typeof spec.pageLevel === 'boolean' ? spec.pageLevel : false;

  /**
   * Flag to force the rule to return as needs review rather than a violation if any of the checks fail.
   * @type {Boolean}
   */
  this.reviewOnFail =
    typeof spec.reviewOnFail === 'boolean' ? spec.reviewOnFail : false;

  /**
   * Checks that any may return true to satisfy rule
   * @type {Array}
   */
  this.any = spec.any || [];

  /**
   * Checks that must all return true to satisfy rule
   * @type {Array}
   */
  this.all = spec.all || [];

  /**
   * Checks that none may return true to satisfy rule
   * @type {Array}
   */
  this.none = spec.none || [];

  /**
   * Tags associated to this rule
   * @type {Array}
   */
  this.tags = spec.tags || [];

  /**
   * Preload necessary for this rule
   */
  this.preload = spec.preload ? true : false;

  if (spec.matches) {
    /**
     * Optional function to test if rule should be run against a node, overrides Rule#matches
     * @type {Function}
     */
    this.matches = createExecutionContext(spec.matches);
  }
}

/**
 * Optionally test each node against a `matches` function to determine if the rule should run against
 * a given node.  Defaults to `true`.
 * @return {Boolean}    Whether the rule should run
 */
Rule.prototype.matches = function matches() {
  return true;
};

/**
 * Selects `HTMLElement`s based on configured selector
 * @param  {Context} context The resolved Context object
 * @param  {Mixed}   options Options specific to this rule
 * @return {Array}           All matching `HTMLElement`s
 */
Rule.prototype.gather = function gather(context, options = {}) {
  const markStart = 'mark_gather_start_' + this.id;
  const markEnd = 'mark_gather_end_' + this.id;
  const markHiddenStart = 'mark_isHidden_start_' + this.id;
  const markHiddenEnd = 'mark_isHidden_end_' + this.id;

  if (options.performanceTimer) {
    performanceTimer.mark(markStart);
  }

  var elements = select(this.selector, context);
  if (this.excludeHidden) {
    if (options.performanceTimer) {
      performanceTimer.mark(markHiddenStart);
    }

    elements = elements.filter(element => {
      return !isHidden(element.actualNode);
    });

    if (options.performanceTimer) {
      performanceTimer.mark(markHiddenEnd);
      performanceTimer.measure(
        'rule_' + this.id + '#gather_axe.utils.isHidden',
        markHiddenStart,
        markHiddenEnd
      );
    }
  }

  if (options.performanceTimer) {
    performanceTimer.mark(markEnd);
    performanceTimer.measure('rule_' + this.id + '#gather', markStart, markEnd);
  }

  return elements;
};

Rule.prototype.runChecks = function runChecks(
  type,
  node,
  options,
  context,
  resolve,
  reject
) {
  var self = this;

  var checkQueue = queue();

  this[type].forEach(c => {
    var check = self._audit.checks[c.id || c];
    var option = getCheckOption(check, self.id, options);
    checkQueue.defer((res, rej) => {
      check.run(node, option, context, res, rej);
    });
  });

  checkQueue
    .then(results => {
      results = results.filter(check => check);
      resolve({ type: type, results: results });
    })
    .catch(reject);
};

/**
 * Run a check for a rule synchronously.
 */
Rule.prototype.runChecksSync = function runChecksSync(
  type,
  node,
  options,
  context
) {
  const self = this;
  let results = [];

  this[type].forEach(c => {
    const check = self._audit.checks[c.id || c];
    const option = getCheckOption(check, self.id, options);
    results.push(check.runSync(node, option, context));
  });

  results = results.filter(check => check);

  return { type: type, results: results };
};

/**
 * Runs the Rule's `evaluate` function
 * @param  {Context}   context  The resolved Context object
 * @param  {Mixed}   options  Options specific to this rule
 * @param  {Function} callback Function to call when evaluate is complete; receives a RuleResult instance
 */
Rule.prototype.run = function run(context, options = {}, resolve, reject) {
  if (options.performanceTimer) {
    this._trackPerformance();
  }

  const q = queue();
  const ruleResult = new RuleResult(this);
  let nodes;

  try {
    // Matches throws an error when it lacks support for document methods
    nodes = this.gatherAndMatchNodes(context, options);
  } catch (error) {
    // Exit the rule execution if matches fails
    reject(new SupportError({ cause: error, ruleId: this.id }));
    return;
  }

  if (options.performanceTimer) {
    this._logGatherPerformance(nodes);
  }

  nodes.forEach(node => {
    q.defer((resolveNode, rejectNode) => {
      var checkQueue = queue();

      ['any', 'all', 'none'].forEach(type => {
        checkQueue.defer((res, rej) => {
          this.runChecks(type, node, options, context, res, rej);
        });
      });

      checkQueue
        .then(results => {
          const result = getResult(results);
          if (result) {
            result.node = new DqElement(node.actualNode, options);
            ruleResult.nodes.push(result);

            // mark rule as incomplete rather than failure for rules with reviewOnFail
            if (this.reviewOnFail) {
              ['any', 'all'].forEach(type => {
                result[type].forEach(checkResult => {
                  if (checkResult.result === false) {
                    checkResult.result = undefined;
                  }
                });
              });

              result.none.forEach(checkResult => {
                if (checkResult.result === true) {
                  checkResult.result = undefined;
                }
              });
            }
          }
          resolveNode();
        })
        .catch(err => rejectNode(err));
    });
  });

  // Defer the rule's execution to prevent "unresponsive script" warnings.
  // See https://github.com/dequelabs/axe-core/pull/1172 for discussion and details.
  q.defer(resolve => setTimeout(resolve, 0));

  if (options.performanceTimer) {
    this._logRulePerformance();
  }

  q.then(() => resolve(ruleResult)).catch(error => reject(error));
};

/**
 * Runs the Rule's `evaluate` function synchronously
 * @param  {Context}   context  The resolved Context object
 * @param  {Mixed}   options  Options specific to this rule
 */
Rule.prototype.runSync = function runSync(context, options = {}) {
  if (options.performanceTimer) {
    this._trackPerformance();
  }

  const ruleResult = new RuleResult(this);
  let nodes;

  try {
    nodes = this.gatherAndMatchNodes(context, options);
  } catch (error) {
    // Exit the rule execution if matches fails
    throw new SupportError({ cause: error, ruleId: this.id });
  }

  if (options.performanceTimer) {
    this._logGatherPerformance(nodes);
  }

  nodes.forEach(node => {
    const results = [];
    ['any', 'all', 'none'].forEach(type => {
      results.push(this.runChecksSync(type, node, options, context));
    });

    const result = getResult(results);
    if (result) {
      result.node = node.actualNode
        ? new DqElement(node.actualNode, options)
        : null;
      ruleResult.nodes.push(result);

      // mark rule as incomplete rather than failure for rules with reviewOnFail
      if (this.reviewOnFail) {
        ['any', 'all'].forEach(type => {
          result[type].forEach(checkResult => {
            if (checkResult.result === false) {
              checkResult.result = undefined;
            }
          });
        });

        result.none.forEach(checkResult => {
          if (checkResult.result === true) {
            checkResult.result = undefined;
          }
        });
      }
    }
  });

  if (options.performanceTimer) {
    this._logRulePerformance();
  }

  return ruleResult;
};

/**
 * Add performance tracking properties to the rule
 * @private
 */
Rule.prototype._trackPerformance = function _trackPerformance() {
  this._markStart = 'mark_rule_start_' + this.id;
  this._markEnd = 'mark_rule_end_' + this.id;
  this._markChecksStart = 'mark_runchecks_start_' + this.id;
  this._markChecksEnd = 'mark_runchecks_end_' + this.id;
};

/**
 * Log performance of rule.gather
 * @private
 * @param {Rule} rule The rule to log
 * @param {Array} nodes Result of rule.gather
 */
Rule.prototype._logGatherPerformance = function _logGatherPerformance(nodes) {
  log('gather (', nodes.length, '):', performanceTimer.timeElapsed() + 'ms');
  performanceTimer.mark(this._markChecksStart);
};

/**
 * Log performance of the rule
 * @private
 * @param {Rule} rule The rule to log
 */
Rule.prototype._logRulePerformance = function _logRulePerformance() {
  performanceTimer.mark(this._markChecksEnd);
  performanceTimer.mark(this._markEnd);
  performanceTimer.measure(
    'runchecks_' + this.id,
    this._markChecksStart,
    this._markChecksEnd
  );

  performanceTimer.measure('rule_' + this.id, this._markStart, this._markEnd);
};

/**
 * Process the results of each check and return the result if a check
 * has a result
 * @private
 * @param {Array} results  Array of each check result
 * @returns {Object|null}
 */
function getResult(results) {
  if (results.length) {
    let hasResults = false;
    const result = {};
    results.forEach(r => {
      const res = r.results.filter(result => result);
      result[r.type] = res;
      if (res.length) {
        hasResults = true;
      }
    });

    if (hasResults) {
      return result;
    }

    return null;
  }
}

/**
 * Selects `HTMLElement`s based on configured selector and filters them based on
 * the rules matches function
 * @param  {Rule} rule The rule to check for after checks
 * @param  {Context} context The resolved Context object
 * @param  {Mixed}   options Options specific to this rule
 * @return {Array}           All matching `HTMLElement`s
 */
Rule.prototype.gatherAndMatchNodes = function gatherAndMatchNodes(
  context,
  options
) {
  const markMatchesStart = 'mark_matches_start_' + this.id;
  const markMatchesEnd = 'mark_matches_end_' + this.id;

  let nodes = this.gather(context, options);

  if (options.performanceTimer) {
    performanceTimer.mark(markMatchesStart);
  }

  nodes = nodes.filter(node => this.matches(node.actualNode, node, context));

  if (options.performanceTimer) {
    performanceTimer.mark(markMatchesEnd);
    performanceTimer.measure(
      'rule_' + this.id + '#matches',
      markMatchesStart,
      markMatchesEnd
    );
  }

  return nodes;
};

/**
 * Iterates the rule's Checks looking for ones that have an after function
 * @private
 * @param  {Rule} rule The rule to check for after checks
 * @return {Array}      Checks that have an after function
 */
function findAfterChecks(rule) {
  return getAllChecks(rule)
    .map(c => {
      var check = rule._audit.checks[c.id || c];
      return check && typeof check.after === 'function' ? check : null;
    })
    .filter(Boolean);
}

/**
 * Finds and collates all results for a given Check on a specific Rule
 * @private
 * @param  {Array} nodes RuleResult#nodes; array of 'detail' objects
 * @param  {String} checkID The ID of the Check to find
 * @return {Array}         Matching CheckResults
 */
function findCheckResults(nodes, checkID) {
  var checkResults = [];
  nodes.forEach(nodeResult => {
    var checks = getAllChecks(nodeResult);
    checks.forEach(checkResult => {
      if (checkResult.id === checkID) {
        checkResult.node = nodeResult.node;
        checkResults.push(checkResult);
      }
    });
  });
  return checkResults;
}

function filterChecks(checks) {
  return checks.filter(check => {
    return check.filtered !== true;
  });
}

function sanitizeNodes(result) {
  var checkTypes = ['any', 'all', 'none'];

  var nodes = result.nodes.filter(detail => {
    var length = 0;
    checkTypes.forEach(type => {
      detail[type] = filterChecks(detail[type]);
      length += detail[type].length;
    });
    return length > 0;
  });

  if (result.pageLevel && nodes.length) {
    nodes = [
      nodes.reduce((a, b) => {
        if (a) {
          checkTypes.forEach(type => {
            a[type].push.apply(a[type], b[type]);
          });
          return a;
        }
      })
    ];
  }
  return nodes;
}

/**
 * Runs all of the Rule's Check#after methods
 * @param  {RuleResult} result  The "pre-after" RuleResult
 * @param  {Mixed} options Options specific to the rule
 * @return {RuleResult}         The RuleResult as filtered by after functions
 */
Rule.prototype.after = function after(result, options) {
  var afterChecks = findAfterChecks(this);
  var ruleID = this.id;
  afterChecks.forEach(check => {
    var beforeResults = findCheckResults(result.nodes, check.id);
    var option = getCheckOption(check, ruleID, options);

    var afterResults = check.after(beforeResults, option);
    beforeResults.forEach(item => {
      // only add the node property for the check.after so we can
      // look at which iframe a check result came from, but we don't
      // want it for the final results object
      delete item.node;
      if (afterResults.indexOf(item) === -1) {
        item.filtered = true;
      }
    });
  });

  result.nodes = sanitizeNodes(result);
  return result;
};

/**
 * Reconfigure a rule after it has been added
 * @param {Object} spec - the attributes to be reconfigured
 */
Rule.prototype.configure = function configure(spec) {
  /*eslint no-eval:0 */

  if (spec.hasOwnProperty('selector')) {
    this.selector = spec.selector;
  }

  if (spec.hasOwnProperty('excludeHidden')) {
    this.excludeHidden =
      typeof spec.excludeHidden === 'boolean' ? spec.excludeHidden : true;
  }

  if (spec.hasOwnProperty('enabled')) {
    this.enabled = typeof spec.enabled === 'boolean' ? spec.enabled : true;
  }

  if (spec.hasOwnProperty('pageLevel')) {
    this.pageLevel =
      typeof spec.pageLevel === 'boolean' ? spec.pageLevel : false;
  }

  if (spec.hasOwnProperty('reviewOnFail')) {
    this.reviewOnFail =
      typeof spec.reviewOnFail === 'boolean' ? spec.reviewOnFail : false;
  }

  if (spec.hasOwnProperty('any')) {
    this.any = spec.any;
  }

  if (spec.hasOwnProperty('all')) {
    this.all = spec.all;
  }

  if (spec.hasOwnProperty('none')) {
    this.none = spec.none;
  }

  if (spec.hasOwnProperty('tags')) {
    this.tags = spec.tags;
  }

  if (spec.hasOwnProperty('matches')) {
    this.matches = createExecutionContext(spec.matches);
  }

  if (spec.impact) {
    assert(
      constants.impact.includes(spec.impact),
      `Impact ${spec.impact} is not a valid impact`
    );
    this.impact = spec.impact;
  }
};

export default Rule;
