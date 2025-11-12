/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
import { Part } from '../lit-html.js';
import { AsyncDirective } from '../async-directive.js';
export declare class UntilDirective extends AsyncDirective {
    private __lastRenderedIndex;
    private __values;
    private __weakThis;
    private __pauser;
    render(...args: Array<unknown>): unknown;
    update(_part: Part, args: Array<unknown>): unknown;
    disconnected(): void;
    reconnected(): void;
}
/**
 * Renders one of a series of values, including Promises, to a Part.
 *
 * Values are rendered in priority order, with the first argument having the
 * highest priority and the last argument having the lowest priority. If a
 * value is a Promise, low-priority values will be rendered until it resolves.
 *
 * The priority of values can be used to create placeholder content for async
 * data. For example, a Promise with pending content can be the first,
 * highest-priority, argument, and a non_promise loading indicator template can
 * be used as the second, lower-priority, argument. The loading indicator will
 * render immediately, and the primary content will render when the Promise
 * resolves.
 *
 * Example:
 *
 * ```js
 * const content = fetch('./content.txt').then(r => r.text());
 * html`${until(content, html`<span>Loading...</span>`)}`
 * ```
 */
export declare const until: (...values: unknown[]) => import("../directive.js").DirectiveResult<typeof UntilDirective>;
/**
 * The type of the class that powers this directive. Necessary for naming the
 * directive's return type.
 */
//# sourceMappingURL=until.d.ts.map