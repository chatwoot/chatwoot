/**
 * Constructor for the result of checks
 * @param {Check} check
 */
function CheckResult(check) {
  /**
   * ID of the check.  Unique in the context of a rule.
   * @type {String}
   */
  this.id = check.id;

  /**
   * Any data passed by Check (by calling `this.data()`)
   * @type {Mixed}
   */
  this.data = null;

  /**
   * Any node that is related to the Check, specified by calling `this.relatedNodes([HTMLElement...])` inside the Check
   * @type {Array}
   */
  this.relatedNodes = [];

  /**
   * The return value of the Check's evaluate function
   * @type {Mixed}
   */
  this.result = null;
}

export default CheckResult;
