/**
 * @license
 * Copyright 2021 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
/**
 * Returns an iterable containing the values in `items` interleaved with the
 * `joiner` value.
 *
 * @example
 *
 * ```ts
 * render() {
 *   return html`
 *     ${join(items, html`<span class="separator">|</span>`)}
 *   `;
 * }
 */
export declare function join<I, J>(items: Iterable<I> | undefined, joiner: (index: number) => J): Iterable<I | J>;
export declare function join<I, J>(items: Iterable<I> | undefined, joiner: J): Iterable<I | J>;
//# sourceMappingURL=join.d.ts.map