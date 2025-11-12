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
import { onBFCacheRestore } from './lib/bfcache.js';
import { bindReporter } from './lib/bindReporter.js';
import { getVisibilityWatcher } from './lib/getVisibilityWatcher.js';
import { initMetric } from './lib/initMetric.js';
import { observe } from './lib/observe.js';
import { onHidden } from './lib/onHidden.js';
import { firstInputPolyfill, resetFirstInputPolyfill, } from './lib/polyfills/firstInputPolyfill.js';
import { runOnce } from './lib/runOnce.js';
import { whenActivated } from './lib/whenActivated.js';
/** Thresholds for FID. See https://web.dev/articles/fid#what_is_a_good_fid_score */
export const FIDThresholds = [100, 300];
/**
 * Calculates the [FID](https://web.dev/articles/fid) value for the current page and
 * calls the `callback` function once the value is ready, along with the
 * relevant `first-input` performance entry used to determine the value. The
 * reported value is a `DOMHighResTimeStamp`.
 *
 * _**Important:** since FID is only reported after the user interacts with the
 * page, it's possible that it will not be reported for some page loads._
 */
export const onFID = (onReport, opts) => {
    // Set defaults
    opts = opts || {};
    whenActivated(() => {
        const visibilityWatcher = getVisibilityWatcher();
        let metric = initMetric('FID');
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
            entries.forEach(handleEntry);
        };
        const po = observe('first-input', handleEntries);
        report = bindReporter(onReport, metric, FIDThresholds, opts.reportAllChanges);
        if (po) {
            onHidden(runOnce(() => {
                handleEntries(po.takeRecords());
                po.disconnect();
            }));
            onBFCacheRestore(() => {
                metric = initMetric('FID');
                report = bindReporter(onReport, metric, FIDThresholds, opts.reportAllChanges);
                // Browsers don't re-emit FID on bfcache restore so fake it until you make it
                resetFirstInputPolyfill();
                firstInputPolyfill(handleEntry);
            });
        }
    });
};
