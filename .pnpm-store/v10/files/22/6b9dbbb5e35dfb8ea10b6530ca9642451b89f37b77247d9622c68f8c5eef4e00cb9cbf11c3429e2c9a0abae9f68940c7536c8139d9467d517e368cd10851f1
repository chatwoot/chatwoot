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

import {getNavigationEntry} from './getNavigationEntry.js';
import {LoadState} from '../types.js';

export const getLoadState = (timestamp: number): LoadState => {
  if (document.readyState === 'loading') {
    // If the `readyState` is 'loading' there's no need to look at timestamps
    // since the timestamp has to be the current time or earlier.
    return 'loading';
  } else {
    const navigationEntry = getNavigationEntry();
    if (navigationEntry) {
      if (timestamp < navigationEntry.domInteractive) {
        return 'loading';
      } else if (
        navigationEntry.domContentLoadedEventStart === 0 ||
        timestamp < navigationEntry.domContentLoadedEventStart
      ) {
        // If the `domContentLoadedEventStart` timestamp has not yet been
        // set, or if the given timestamp is less than that value.
        return 'dom-interactive';
      } else if (
        navigationEntry.domComplete === 0 ||
        timestamp < navigationEntry.domComplete
      ) {
        // If the `domComplete` timestamp has not yet been
        // set, or if the given timestamp is less than that value.
        return 'dom-content-loaded';
      }
    }
  }
  // If any of the above fail, default to loaded. This could really only
  // happy if the browser doesn't support the performance timeline, which
  // most likely means this code would never run anyway.
  return 'complete';
};
