import log from '../log';

/**
 * Performance measuring utility shimming the User Timing API
 *
 * https://www.html5rocks.com/en/tutorials/webperformance/usertiming/
 * http://caniuse.com/#search=User%20Timing
 *
 */
const performanceTimer = (() => {
  /**
   * Get a time/date object using performance.now() if supported
   * @return {DOMTimeStamp}
   */
  function now() {
    if (window.performance && window.performance) {
      return window.performance.now();
    }
  }
  var originalTime = null;
  var lastRecordedTime = now();

  /**
   * @typedef {utils.performanceTimer} Public API Methods
   */
  return {
    /**
     * @member {Function} start Kicks off performance timing for overall axe audit
     */
    start() {
      this.mark('mark_axe_start');
    },
    /**
     * @member {Function} end Concludes performance timing, compares start/end marks
     */
    end() {
      this.mark('mark_axe_end');
      this.measure('axe', 'mark_axe_start', 'mark_axe_end');

      this.logMeasures('axe');
    },
    /**
     * @member {Function} auditStart Starts an audit for a page or frame
     */
    auditStart() {
      this.mark('mark_audit_start');
    },
    /**
     * @member {Function} auditEnd Ends an audit for a page or frame, logs measurement of start/end marks
     */
    auditEnd() {
      this.mark('mark_audit_end');
      this.measure('audit_start_to_end', 'mark_audit_start', 'mark_audit_end');
      // log audit/rule measures
      this.logMeasures();
    },
    /**
     * @member {Function} mark Shims creating a new named time stamp, called a mark
     * @param {String} markName String name to record how long it took to get there.
     * A mark that already exists will be overwritten.
     *
     */
    mark(markName) {
      if (window.performance && window.performance.mark !== undefined) {
        window.performance.mark(markName);
      }
    },
    /**
     * @member {Function} measure Shims creating a measure to compare two marks, which can be logged
     * @param {String} measureName String name to log what is being compared.
     * Measures that already exist will be overwritten with a new time stamp.
     * @param {String} startMark String name of mark to start measuring
     * @param {String} endMark String name of mark to end measuring
     */
    measure(measureName, startMark, endMark) {
      if (window.performance && window.performance.measure !== undefined) {
        window.performance.measure(measureName, startMark, endMark);
      }
    },
    /**
     * @member {Function} logMeasures Iterates through measures and logs any that exist
     */
    logMeasures(measureName) {
      function logMeasure(req) {
        log('Measure ' + req.name + ' took ' + req.duration + 'ms');
      }
      if (
        window.performance &&
        window.performance.getEntriesByType !== undefined
      ) {
        // only output measures that were started after axe started, otherwise
        // we get measures made by the page before axe ran (which is confusing)
        var axeStart = window.performance.getEntriesByName('mark_axe_start')[0];
        var measures = window.performance
          .getEntriesByType('measure')
          .filter(measure => measure.startTime >= axeStart.startTime);
        for (var i = 0; i < measures.length; ++i) {
          var req = measures[i];
          if (req.name === measureName) {
            logMeasure(req);
            return;
          }
          logMeasure(req);
        }
      }
    },
    /**
     * @member {Function} timeElapsed Records time since last audit
     * @return {DOMTimeStamp}
     */
    timeElapsed() {
      return now() - lastRecordedTime;
    },
    /**
     * @member {Function} reset Resets the time for a new audit
     */
    reset() {
      if (!originalTime) {
        originalTime = now();
      }
      lastRecordedTime = now();
    }
  };
})();

export default performanceTimer;
