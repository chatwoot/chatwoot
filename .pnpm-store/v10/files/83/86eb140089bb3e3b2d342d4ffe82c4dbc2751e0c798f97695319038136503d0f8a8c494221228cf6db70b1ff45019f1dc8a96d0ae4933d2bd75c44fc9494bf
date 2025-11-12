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

import type {LoadState, Metric} from './base.js';

/**
 * A CLS-specific version of the Metric object.
 */
export interface CLSMetric extends Metric {
  name: 'CLS';
  entries: LayoutShift[];
}

/**
 * An object containing potentially-helpful debugging information that
 * can be sent along with the CLS value for the current page visit in order
 * to help identify issues happening to real-users in the field.
 */
export interface CLSAttribution {
  /**
   * A selector identifying the first element (in document order) that
   * shifted when the single largest layout shift contributing to the page's
   * CLS score occurred.
   */
  largestShiftTarget?: string;
  /**
   * The time when the single largest layout shift contributing to the page's
   * CLS score occurred.
   */
  largestShiftTime?: DOMHighResTimeStamp;
  /**
   * The layout shift score of the single largest layout shift contributing to
   * the page's CLS score.
   */
  largestShiftValue?: number;
  /**
   * The `LayoutShiftEntry` representing the single largest layout shift
   * contributing to the page's CLS score. (Useful when you need more than just
   * `largestShiftTarget`, `largestShiftTime`, and `largestShiftValue`).
   */
  largestShiftEntry?: LayoutShift;
  /**
   * The first element source (in document order) among the `sources` list
   * of the `largestShiftEntry` object. (Also useful when you need more than
   * just `largestShiftTarget`, `largestShiftTime`, and `largestShiftValue`).
   */
  largestShiftSource?: LayoutShiftAttribution;
  /**
   * The loading state of the document at the time when the largest layout
   * shift contribution to the page's CLS score occurred (see `LoadState`
   * for details).
   */
  loadState?: LoadState;
}

/**
 * A CLS-specific version of the Metric object with attribution.
 */
export interface CLSMetricWithAttribution extends CLSMetric {
  attribution: CLSAttribution;
}
