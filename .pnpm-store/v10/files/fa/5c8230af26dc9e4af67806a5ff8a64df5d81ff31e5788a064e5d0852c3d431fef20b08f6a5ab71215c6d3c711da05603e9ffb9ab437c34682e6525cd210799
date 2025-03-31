import { WINDOW } from '../../../types.js';

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


const onHidden = (cb) => {
  const onHiddenOrPageHide = (event) => {
    if (event.type === 'pagehide' || (WINDOW.document && WINDOW.document.visibilityState === 'hidden')) {
      cb(event);
    }
  };

  if (WINDOW.document) {
    addEventListener('visibilitychange', onHiddenOrPageHide, true);
    // Some browsers have buggy implementations of visibilitychange,
    // so we use pagehide in addition, just to be safe.
    addEventListener('pagehide', onHiddenOrPageHide, true);
  }
};

export { onHidden };
//# sourceMappingURL=onHidden.js.map
