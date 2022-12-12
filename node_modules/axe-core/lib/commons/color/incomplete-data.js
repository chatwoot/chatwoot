/**
 * API for handling incomplete color data
 * @namespace axe.commons.color.incompleteData
 * @inner
 */
let data = {};
const incompleteData = {
  /**
   * Store incomplete data by key with a string value
   * @method set
   * @memberof axe.commons.color.incompleteData
   * @instance
   * @param {String} key Identifier for missing data point (fgColor, bgColor, etc.)
   * @param {String} reason Missing data reason to match message template
   */
  set: function(key, reason) {
    if (typeof key !== 'string') {
      throw new Error('Incomplete data: key must be a string');
    }
    if (reason) {
      data[key] = reason;
    }
    return data[key];
  },
  /**
   * Get incomplete data by key
   * @method get
   * @memberof axe.commons.color.incompleteData
   * @instance
   * @param {String} key 	Identifier for missing data point (fgColor, bgColor, etc.)
   * @return {String} String for reason we couldn't tell
   */
  get: function(key) {
    return data[key];
  },
  /**
   * Clear incomplete data on demand
   * @method clear
   * @memberof axe.commons.color.incompleteData
   * @instance
   */
  clear: function() {
    data = {};
  }
};

export default incompleteData;
