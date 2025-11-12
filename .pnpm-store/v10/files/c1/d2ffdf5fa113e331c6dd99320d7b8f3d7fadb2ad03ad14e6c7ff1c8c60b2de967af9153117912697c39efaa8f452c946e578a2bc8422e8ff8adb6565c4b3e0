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

interface PerformanceEntryMap {
  'event': PerformanceEventTiming[];
  'first-input': PerformanceEventTiming[];
  'layout-shift': LayoutShift[];
  'largest-contentful-paint': LargestContentfulPaint[];
  'long-animation-frame': PerformanceLongAnimationFrameTiming[];
  'paint': PerformancePaintTiming[];
  'navigation': PerformanceNavigationTiming[];
  'resource': PerformanceResourceTiming[];
}

/**
 * Takes a performance entry type and a callback function, and creates a
 * `PerformanceObserver` instance that will observe the specified entry type
 * with buffering enabled and call the callback _for each entry_.
 *
 * This function also feature-detects entry support and wraps the logic in a
 * try/catch to avoid errors in unsupporting browsers.
 */
export const observe = <K extends keyof PerformanceEntryMap>(
  type: K,
  callback: (entries: PerformanceEntryMap[K]) => void,
  opts?: PerformanceObserverInit,
): PerformanceObserver | undefined => {
  try {
    if (PerformanceObserver.supportedEntryTypes.includes(type)) {
      const po = new PerformanceObserver((list) => {
        // Delay by a microtask to workaround a bug in Safari where the
        // callback is invoked immediately, rather than in a separate task.
        // See: https://github.com/GoogleChrome/web-vitals/issues/277
        Promise.resolve().then(() => {
          callback(list.getEntries() as PerformanceEntryMap[K]);
        });
      });
      po.observe(
        Object.assign(
          {
            type,
            buffered: true,
          },
          opts || {},
        ) as PerformanceObserverInit,
      );
      return po;
    }
  } catch (e) {
    // Do nothing.
  }
  return;
};
