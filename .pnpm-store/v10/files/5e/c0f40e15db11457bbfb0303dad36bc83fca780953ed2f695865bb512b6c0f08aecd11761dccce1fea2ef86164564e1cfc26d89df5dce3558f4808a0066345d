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

import {onBFCacheRestore} from './lib/bfcache.js';
import {bindReporter} from './lib/bindReporter.js';
import {initMetric} from './lib/initMetric.js';
import {
  DEFAULT_DURATION_THRESHOLD,
  processInteractionEntry,
  estimateP98LongestInteraction,
  resetInteractions,
} from './lib/interactions.js';
import {observe} from './lib/observe.js';
import {onHidden} from './lib/onHidden.js';
import {initInteractionCountPolyfill} from './lib/polyfills/interactionCountPolyfill.js';
import {whenActivated} from './lib/whenActivated.js';
import {whenIdle} from './lib/whenIdle.js';

import {INPMetric, MetricRatingThresholds, ReportOpts} from './types.js';

/** Thresholds for INP. See https://web.dev/articles/inp#what_is_a_good_inp_score */
export const INPThresholds: MetricRatingThresholds = [200, 500];

/**
 * Calculates the [INP](https://web.dev/articles/inp) value for the current
 * page and calls the `callback` function once the value is ready, along with
 * the `event` performance entries reported for that interaction. The reported
 * value is a `DOMHighResTimeStamp`.
 *
 * A custom `durationThreshold` configuration option can optionally be passed to
 * control what `event-timing` entries are considered for INP reporting. The
 * default threshold is `40`, which means INP scores of less than 40 are
 * reported as 0. Note that this will not affect your 75th percentile INP value
 * unless that value is also less than 40 (well below the recommended
 * [good](https://web.dev/articles/inp#what_is_a_good_inp_score) threshold).
 *
 * If the `reportAllChanges` configuration option is set to `true`, the
 * `callback` function will be called as soon as the value is initially
 * determined as well as any time the value changes throughout the page
 * lifespan.
 *
 * _**Important:** INP should be continually monitored for changes throughout
 * the entire lifespan of a page—including if the user returns to the page after
 * it's been hidden/backgrounded. However, since browsers often [will not fire
 * additional callbacks once the user has backgrounded a
 * page](https://developer.chrome.com/blog/page-lifecycle-api/#advice-hidden),
 * `callback` is always called when the page's visibility state changes to
 * hidden. As a result, the `callback` function might be called multiple times
 * during the same page load._
 */
export const onINP = (
  onReport: (metric: INPMetric) => void,
  opts?: ReportOpts,
) => {
  // Return if the browser doesn't support all APIs needed to measure INP.
  if (
    !(
      'PerformanceEventTiming' in self &&
      'interactionId' in PerformanceEventTiming.prototype
    )
  ) {
    return;
  }

  // Set defaults
  opts = opts || {};

  whenActivated(() => {
    // TODO(philipwalton): remove once the polyfill is no longer needed.
    initInteractionCountPolyfill();

    let metric = initMetric('INP');
    let report: ReturnType<typeof bindReporter>;

    const handleEntries = (entries: INPMetric['entries']) => {
      // Queue the `handleEntries()` callback in the next idle task.
      // This is needed to increase the chances that all event entries that
      // occurred between the user interaction and the next paint
      // have been dispatched. Note: there is currently an experiment
      // running in Chrome (EventTimingKeypressAndCompositionInteractionId)
      // 123+ that if rolled out fully may make this no longer necessary.
      whenIdle(() => {
        entries.forEach(processInteractionEntry);

        const inp = estimateP98LongestInteraction();

        if (inp && inp.latency !== metric.value) {
          metric.value = inp.latency;
          metric.entries = inp.entries;
          report();
        }
      });
    };

    const po = observe('event', handleEntries, {
      // Event Timing entries have their durations rounded to the nearest 8ms,
      // so a duration of 40ms would be any event that spans 2.5 or more frames
      // at 60Hz. This threshold is chosen to strike a balance between usefulness
      // and performance. Running this callback for any interaction that spans
      // just one or two frames is likely not worth the insight that could be
      // gained.
      durationThreshold: opts!.durationThreshold ?? DEFAULT_DURATION_THRESHOLD,
    });

    report = bindReporter(
      onReport,
      metric,
      INPThresholds,
      opts!.reportAllChanges,
    );

    if (po) {
      // Also observe entries of type `first-input`. This is useful in cases
      // where the first interaction is less than the `durationThreshold`.
      po.observe({type: 'first-input', buffered: true});

      onHidden(() => {
        handleEntries(po.takeRecords() as INPMetric['entries']);
        report(true);
      });

      // Only report after a bfcache restore if the `PerformanceObserver`
      // successfully registered.
      onBFCacheRestore(() => {
        resetInteractions();

        metric = initMetric('INP');
        report = bindReporter(
          onReport,
          metric,
          INPThresholds,
          opts!.reportAllChanges,
        );
      });
    }
  });
};
