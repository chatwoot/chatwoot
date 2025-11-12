/*
 * Copyright 2024 Google LLC
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

import {onHidden} from './onHidden.js';
import {runOnce} from './runOnce.js';

/**
 * Runs the passed callback during the next idle period, or immediately
 * if the browser's visibility state is (or becomes) hidden.
 */
export const whenIdle = (cb: () => void): number => {
  const rIC = self.requestIdleCallback || self.setTimeout;

  let handle = -1;
  cb = runOnce(cb);
  // If the document is hidden, run the callback immediately, otherwise
  // race an idle callback with the next `visibilitychange` event.
  if (document.visibilityState === 'hidden') {
    cb();
  } else {
    handle = rIC(cb);
    onHidden(cb);
  }
  return handle;
};
