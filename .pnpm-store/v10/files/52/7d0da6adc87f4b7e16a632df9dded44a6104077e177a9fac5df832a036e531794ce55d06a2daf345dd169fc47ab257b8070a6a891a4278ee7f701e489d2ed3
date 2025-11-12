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
 * An FID-specific version of the Metric object.
 */
export interface FIDMetric extends Metric {
  name: 'FID';
  entries: PerformanceEventTiming[];
}

/**
 * An object containing potentially-helpful debugging information that
 * can be sent along with the FID value for the current page visit in order
 * to help identify issues happening to real-users in the field.
 */
export interface FIDAttribution {
  /**
   * A selector identifying the element that the user interacted with. This
   * element will be the `target` of the `event` dispatched.
   */
  eventTarget: string;
  /**
   * The time when the user interacted. This time will match the `timeStamp`
   * value of the `event` dispatched.
   */
  eventTime: number;
  /**
   * The `type` of the `event` dispatched from the user interaction.
   */
  eventType: string;
  /**
   * The `PerformanceEventTiming` entry corresponding to FID.
   */
  eventEntry: PerformanceEventTiming;
  /**
   * The loading state of the document at the time when the first interaction
   * occurred (see `LoadState` for details). If the first interaction occurred
   * while the document was loading and executing script (e.g. usually in the
   * `dom-interactive` phase) it can result in long input delays.
   */
  loadState: LoadState;
}

/**
 * An FID-specific version of the Metric object with attribution.
 */
export interface FIDMetricWithAttribution extends FIDMetric {
  attribution: FIDAttribution;
}
