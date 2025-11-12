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
import { doubleRAF } from './lib/doubleRAF.js';
import { getActivationStart } from './lib/getActivationStart.js';
import { getVisibilityWatcher } from './lib/getVisibilityWatcher.js';
import { initMetric } from './lib/initMetric.js';
import { observe } from './lib/observe.js';
import { onHidden } from './lib/onHidden.js';
import { runOnce } from './lib/runOnce.js';
import { whenActivated } from './lib/whenActivated.js';
import { whenIdle } from './lib/whenIdle.js';
/** Thresholds for LCP. See https://web.dev/articles/lcp#what_is_a_good_lcp_score */
export const LCPThresholds = [2500, 4000];
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
export const onLCP = (onReport, opts) => {
    // Set defaults
    opts = opts || {};
    whenActivated(() => {
        const visibilityWatcher = getVisibilityWatcher();
        let metric = initMetric('LCP');
        let report;
        const handleEntries = (entries) => {
            // If reportAllChanges is set then call this function for each entry,
            // otherwise only consider the last one.
            if (!opts.reportAllChanges) {
                entries = entries.slice(-1);
            }
            entries.forEach((entry) => {
                // Only report if the page wasn't hidden prior to LCP.
                if (entry.startTime < visibilityWatcher.firstHiddenTime) {
                    // The startTime attribute returns the value of the renderTime if it is
                    // not 0, and the value of the loadTime otherwise. The activationStart
                    // reference is used because LCP should be relative to page activation
                    // rather than navigation start if the page was prerendered. But in cases
                    // where `activationStart` occurs after the LCP, this time should be
                    // clamped at 0.
                    metric.value = Math.max(entry.startTime - getActivationStart(), 0);
                    metric.entries = [entry];
                    report();
                }
            });
        };
        const po = observe('largest-contentful-paint', handleEntries);
        if (po) {
            report = bindReporter(onReport, metric, LCPThresholds, opts.reportAllChanges);
            const stopListening = runOnce(() => {
                if (!reportedMetricIDs[metric.id]) {
                    handleEntries(po.takeRecords());
                    po.disconnect();
                    reportedMetricIDs[metric.id] = true;
                    report(true);
                }
            });
            // Stop listening after input. Note: while scrolling is an input that
            // stops LCP observation, it's unreliable since it can be programmatically
            // generated. See: https://github.com/GoogleChrome/web-vitals/issues/75
            ['keydown', 'click'].forEach((type) => {
                // Wrap in a setTimeout so the callback is run in a separate task
                // to avoid extending the keyboard/click handler to reduce INP impact
                // https://github.com/GoogleChrome/web-vitals/issues/383
                addEventListener(type, () => whenIdle(stopListening), {
                    once: true,
                    capture: true,
                });
            });
            onHidden(stopListening);
            // Only report after a bfcache restore if the `PerformanceObserver`
            // successfully registered.
            onBFCacheRestore((event) => {
                metric = initMetric('LCP');
                report = bindReporter(onReport, metric, LCPThresholds, opts.reportAllChanges);
                doubleRAF(() => {
                    metric.value = performance.now() - event.timeStamp;
                    reportedMetricIDs[metric.id] = true;
                    report(true);
                });
            });
        }
    });
};
