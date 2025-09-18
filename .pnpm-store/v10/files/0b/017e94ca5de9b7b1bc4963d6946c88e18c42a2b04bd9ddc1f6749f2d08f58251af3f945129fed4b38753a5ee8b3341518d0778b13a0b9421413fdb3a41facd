Object.defineProperty(exports, '__esModule', { value: true });

const types = require('../../types.js');
const bindReporter = require('./lib/bindReporter.js');
const getActivationStart = require('./lib/getActivationStart.js');
const getVisibilityWatcher = require('./lib/getVisibilityWatcher.js');
const initMetric = require('./lib/initMetric.js');
const observe = require('./lib/observe.js');
const onHidden = require('./lib/onHidden.js');
const runOnce = require('./lib/runOnce.js');
const whenActivated = require('./lib/whenActivated.js');

/*
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/** Thresholds for LCP. See https://web.dev/articles/lcp#what_is_a_good_lcp_score */
const LCPThresholds = [2500, 4000];

const reportedMetricIDs = {};

/**
 * Calculates the [LCP](https://web.dev/articles/lcp) value for the current page and
 * calls the `callback` function once the value is ready (along with the
 * relevant `largest-contentful-paint` performance entry used to determine the
 * value). The reported value is a `DOMHighResTimeStamp`.
 *
 * If the `reportAllChanges` configuration option is set to `true`, the
 * `callback` function will be called any time a new `largest-contentful-paint`
 * performance entry is dispatched, or once the final value of the metric has
 * been determined.
 */
const onLCP = (onReport, opts = {}) => {
  whenActivated.whenActivated(() => {
    const visibilityWatcher = getVisibilityWatcher.getVisibilityWatcher();
    const metric = initMetric.initMetric('LCP');
    let report;

    const handleEntries = (entries) => {
      const lastEntry = entries[entries.length - 1] ;
      if (lastEntry) {
        // Only report if the page wasn't hidden prior to LCP.
        if (lastEntry.startTime < visibilityWatcher.firstHiddenTime) {
          // The startTime attribute returns the value of the renderTime if it is
          // not 0, and the value of the loadTime otherwise. The activationStart
          // reference is used because LCP should be relative to page activation
          // rather than navigation start if the page was prerendered. But in cases
          // where `activationStart` occurs after the LCP, this time should be
          // clamped at 0.
          metric.value = Math.max(lastEntry.startTime - getActivationStart.getActivationStart(), 0);
          metric.entries = [lastEntry];
          report();
        }
      }
    };

    const po = observe.observe('largest-contentful-paint', handleEntries);

    if (po) {
      report = bindReporter.bindReporter(onReport, metric, LCPThresholds, opts.reportAllChanges);

      const stopListening = runOnce.runOnce(() => {
        if (!reportedMetricIDs[metric.id]) {
          handleEntries(po.takeRecords() );
          po.disconnect();
          reportedMetricIDs[metric.id] = true;
          report(true);
        }
      });

      // Stop listening after input. Note: while scrolling is an input that
      // stops LCP observation, it's unreliable since it can be programmatically
      // generated. See: https://github.com/GoogleChrome/web-vitals/issues/75
      ['keydown', 'click'].forEach(type => {
        if (types.WINDOW.document) {
          // Wrap in a setTimeout so the callback is run in a separate task
          // to avoid extending the keyboard/click handler to reduce INP impact
          // https://github.com/GoogleChrome/web-vitals/issues/383
          addEventListener(type, () => setTimeout(stopListening, 0), true);
        }
      });

      onHidden.onHidden(stopListening);
    }
  });
};

exports.LCPThresholds = LCPThresholds;
exports.onLCP = onLCP;
//# sourceMappingURL=getLCP.js.map
