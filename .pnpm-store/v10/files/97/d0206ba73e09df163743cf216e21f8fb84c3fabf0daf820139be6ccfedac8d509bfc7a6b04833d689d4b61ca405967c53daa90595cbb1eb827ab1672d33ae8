/**
 * @license
 * Copyright 2021 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
export function* range(startOrEnd, end, step = 1) {
    const start = end === undefined ? 0 : startOrEnd;
    end !== null && end !== void 0 ? end : (end = startOrEnd);
    for (let i = start; step > 0 ? i < end : end < i; i += step) {
        yield i;
    }
}
//# sourceMappingURL=range.js.map