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
export var getFID = function (onReport, reportAllChanges) {
    var visibilityWatcher = getVisibilityWatcher();
    var metric = initMetric('FID');
    var report;
    var entryHandler = function (entry) {
        // Only report if the page wasn't hidden prior to the first input.
        if (report && entry.startTime < visibilityWatcher.firstHiddenTime) {
            metric.value = entry.processingStart - entry.startTime;
            metric.entries.push(entry);
            report(true);
        }
    };
    var po = observe('first-input', entryHandler);
    if (po) {
        report = bindReporter(onReport, metric, reportAllChanges);
        onHidden(function () {
            po.takeRecords().map(entryHandler);
            po.disconnect();
        }, true);
    }
};
//# sourceMappingURL=getFID.js.map