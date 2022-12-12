import constants from '../constants';

/**
 * Constructor for the result of Rules
 * @param {Rule} rule
 */
function RuleResult(rule) {
  /**
   * The ID of the Rule whom this result belongs to
   * @type {String}
   */
  this.id = rule.id;

  /**
   * The calculated result of the Rule, either PASS, FAIL or NA
   * @type {String}
   */
  this.result = constants.NA;

  /**
   * Whether the Rule is a "pageLevel" rule
   * @type {Boolean}
   */
  this.pageLevel = rule.pageLevel;

  /**
   * Impact of the violation
   * @type {String}  Plain-english impact or null if rule passes
   */
  this.impact = null;

  /**
   * Holds information regarding nodes and individual CheckResults
   * @type {Array}
   */
  this.nodes = [];
}

export default RuleResult;
