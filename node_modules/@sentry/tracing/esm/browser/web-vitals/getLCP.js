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
import { bindReporter } from './lib/bindReporter';
import { getVisibilityWatcher } from './lib/getVisibilityWatcher';
import { initMetric } from './lib/initMetric';
import { observe } from './lib/observe';
import { onHidden } from './lib/onHidden';
var reportedMetricIDs = {};
export var getLCP = function (onReport, reportAllChanges) {
    var visibilityWatcher = getVisibilityWatcher();
    var metric = initMetric('LCP');
    var report;
    var entryHandler = function (entry) {
        // The startTime attribute returns the value of the renderTime if it is not 0,
        // and the value of the loadTime otherwise.
        var value = entry.startTime;
        // If the page was hidden prior to paint time of the entry,
        // ignore it and mark the metric as final, otherwise add the entry.
        if (value < visibilityWatcher.firstHiddenTime) {
            metric.value = value;
            metric.entries.push(entry);
        }
        if (report) {
            report();
        }
    };
    var po = observe('largest-contentful-paint', entryHandler);
    if (po) {
        report = bindReporter(onReport, metric, reportAllChanges);
        var stopListening_1 = function () {
            if (!reportedMetricIDs[metric.id]) {
                po.takeRecords().map(entryHandler);
                po.disconnect();
                reportedMetricIDs[metric.id] = true;
                report(true);
            }
        };
        // Stop listening after input. Note: while scrolling is an input that
        // stop LCP observation, it's unreliable since it can be programmatically
        // generated. See: https://github.com/GoogleChrome/web-vitals/issues/75
        ['keydown', 'click'].forEach(function (type) {
            addEventListener(type, stopListening_1, { once: true, capture: true });
        });
        onHidden(stopListening_1, true);
    }
};
//# sourceMappingURL=getLCP.js.map