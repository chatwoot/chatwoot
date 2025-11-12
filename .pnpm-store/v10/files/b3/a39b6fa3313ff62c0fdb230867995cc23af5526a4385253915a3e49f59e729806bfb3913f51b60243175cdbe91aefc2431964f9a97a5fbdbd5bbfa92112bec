/*
 * Copyright 2022 Google LLC
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
import { getLoadState } from '../lib/getLoadState.js';
import { getSelector } from '../lib/getSelector.js';
import { onCLS as unattributedOnCLS } from '../onCLS.js';
const getLargestLayoutShiftEntry = (entries) => {
    return entries.reduce((a, b) => (a && a.value > b.value ? a : b));
};
const getLargestLayoutShiftSource = (sources) => {
    return sources.find((s) => s.node && s.node.nodeType === 1) || sources[0];
};
const attributeCLS = (metric) => {
    // Use an empty object if no other attribution has been set.
    let attribution = {};
    if (metric.entries.length) {
        const largestEntry = getLargestLayoutShiftEntry(metric.entries);
        if (largestEntry && largestEntry.sources && largestEntry.sources.length) {
            const largestSource = getLargestLayoutShiftSource(largestEntry.sources);
            if (largestSource) {
                attribution = {
                    largestShiftTarget: getSelector(largestSource.node),
                    largestShiftTime: largestEntry.startTime,
                    largestShiftValue: largestEntry.value,
                    largestShiftSource: largestSource,
                    largestShiftEntry: largestEntry,
                    loadState: getLoadState(largestEntry.startTime),
                };
            }
        }
    }
    // Use Object.assign to set property to keep tsc happy.
    const metricWithAttribution = Object.assign(metric, { attribution });
    return metricWithAttribution;
};
/**
 * Calculates the [CLS](https://web.dev/articles/cls) value for the current page and
 * calls the `callback` function once the value is ready to be reported, along
 * with all `layout-shift` performance entries that were used in the metric
 * value calculation. The reported value is a `double` (corresponding to a
 * [layout shift score](https://web.dev/articles/cls#layout_shift_score)).
 *
 * If the `reportAllChanges` configuration option is set to `true`, the
 * `callback` function will be called as soon as the value is initially
 * determined as well as any time the value changes throughout the page
 * lifespan.
 *
 * _**Important:** CLS should be continually monitored for changes throughout
 * the entire lifespan of a page—including if the user returns to the page after
 * it's been hidden/backgrounded. However, since browsers often [will not fire
 * additional callbacks once the user has backgrounded a
 * page](https://developer.chrome.com/blog/page-lifecycle-api/#advice-hidden),
 * `callback` is always called when the page's visibility state changes to
 * hidden. As a result, the `callback` function might be called multiple times
 * during the same page load._
 */
export const onCLS = (onReport, opts) => {
    unattributedOnCLS((metric) => {
        const metricWithAttribution = attributeCLS(metric);
        onReport(metricWithAttribution);
    }, opts);
};
