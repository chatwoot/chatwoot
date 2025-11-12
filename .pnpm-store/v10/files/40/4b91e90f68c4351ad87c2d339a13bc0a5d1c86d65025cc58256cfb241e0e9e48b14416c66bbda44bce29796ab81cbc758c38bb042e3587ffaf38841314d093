/**
 * @license
 * Copyright 2021 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
export function* join(items, joiner) {
    const isFunction = typeof joiner === 'function';
    if (items !== undefined) {
        let i = -1;
        for (const value of items) {
            if (i > -1) {
                yield isFunction ? joiner(i) : joiner;
            }
            i++;
            yield value;
        }
    }
}
//# sourceMappingURL=join.js.map