/**
 * @license
 * Copyright 2018 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
import { Part } from '../lit-html.js';
import { Directive, DirectiveParameters } from '../directive.js';
declare class GuardDirective extends Directive {
    private _previousValue;
    render(_value: unknown, f: () => unknown): unknown;
    update(_part: Part, [value, f]: DirectiveParameters<this>): unknown;
}
/**
 * Prevents re-render of a template function until a single value or an array of
 * values changes.
 *
 * Values are checked against previous values with strict equality (`===`), and
 * so the check won't detect nested property changes inside objects or arrays.
 * Arrays values have each item checked against the previous value at the same
 * index with strict equality. Nested arrays are also checked only by strict
 * equality.
 *
 * Example:
 *
 * ```js
 * html`
 *   <div>
 *     ${guard([user.id, company.id], () => html`...`)}
 *   </div>
 * `
 * ```
 *
 * In this case, the template only rerenders if either `user.id` or `company.id`
 * changes.
 *
 * guard() is useful with immutable data patterns, by preventing expensive work
 * until data updates.
 *
 * Example:
 *
 * ```js
 * html`
 *   <div>
 *     ${guard([immutableItems], () => immutableItems.map(i => html`${i}`))}
 *   </div>
 * `
 * ```
 *
 * In this case, items are mapped over only when the array reference changes.
 *
 * @param value the value to check before re-rendering
 * @param f the template function
 */
export declare const guard: (_value: unknown, f: () => unknown) => import("../directive.js").DirectiveResult<typeof GuardDirective>;
/**
 * The type of the class that powers this directive. Necessary for naming the
 * directive's return type.
 */
export type { GuardDirective };
//# sourceMappingURL=guard.d.ts.map