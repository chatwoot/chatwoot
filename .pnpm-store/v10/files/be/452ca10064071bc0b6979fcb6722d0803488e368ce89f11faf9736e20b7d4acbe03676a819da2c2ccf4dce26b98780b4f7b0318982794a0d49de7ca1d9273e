Object.defineProperty(exports, '__esModule', { value: true });

const bindReporter = require('./lib/bindReporter.js');
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


/** Thresholds for FID. See https://web.dev/articles/fid#what_is_a_good_fid_score */
const FIDThresholds = [100, 300];

/**
 * Calculates the [FID](https://web.dev/articles/fid) value for the current page and
 * calls the `callback` function once the value is ready, along with the
 * relevant `first-input` performance entry used to determine the value. The
 * reported value is a `DOMHighResTimeStamp`.
 *
 * _**Important:** since FID is only reported after the user interacts with the
 * page, it's possible that it will not be reported for some page loads._
 */
const onFID = (onReport, opts = {}) => {
  whenActivated.whenActivated(() => {
    const visibilityWatcher = getVisibilityWatcher.getVisibilityWatcher();
    const metric = initMetric.initMetric('FID');
    // eslint-disable-next-line prefer-const
    let report;

    const handleEntry = (entry) => {
      // Only report if the page wasn't hidden prior to the first input.
      if (entry.startTime < visibilityWatcher.firstHiddenTime) {
        metric.value = entry.processingStart - entry.startTime;
        metric.entries.push(entry);
        report(true);
      }
    };

    const handleEntries = (entries) => {
      (entries ).forEach(handleEntry);
    };

    const po = observe.observe('first-input', handleEntries);
    report = bindReporter.bindReporter(onReport, metric, FIDThresholds, opts.reportAllChanges);

    if (po) {
      onHidden.onHidden(
        runOnce.runOnce(() => {
          handleEntries(po.takeRecords() );
          po.disconnect();
        }),
      );
    }
  });
};

exports.FIDThresholds = FIDThresholds;
exports.onFID = onFID;
//# sourceMappingURL=getFID.js.map
