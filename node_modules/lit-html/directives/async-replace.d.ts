/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
import { ChildPart, noChange } from '../lit-html.js';
import { DirectiveParameters } from '../directive.js';
import { AsyncDirective } from '../async-directive.js';
declare type Mapper<T> = (v: T, index?: number) => unknown;
export declare class AsyncReplaceDirective extends AsyncDirective {
    private __value?;
    private __weakThis;
    private __pauser;
    render<T>(value: AsyncIterable<T>, _mapper?: Mapper<T>): symbol;
    update(_part: ChildPart, [value, mapper]: DirectiveParameters<this>): typeof noChange | undefined;
    protected commitValue(value: unknown, _index: number): void;
    disconnected(): void;
    reconnected(): void;
}
/**
 * A directive that renders the items of an async iterable[1], replacing
 * previous values with new values, so that only one value is ever rendered
 * at a time. This directive may be used in any expression type.
 *
 * Async iterables are objects with a `[Symbol.asyncIterator]` method, which
 * returns an iterator who's `next()` method returns a Promise. When a new
 * value is available, the Promise resolves and the value is rendered to the
 * Part controlled by the directive. If another value other than this
 * directive has been set on the Part, the iterable will no longer be listened
 * to and new values won't be written to the Part.
 *
 * [1]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/for-await...of
 *
 * @param value An async iterable
 * @param mapper An optional function that maps from (value, index) to another
 *     value. Useful for generating templates for each item in the iterable.
 */
export declare const asyncReplace: (value: AsyncIterable<unknown>, _mapper?: Mapper<unknown> | undefined) => import("../directive.js").DirectiveResult<typeof AsyncReplaceDirective>;
export {};
//# sourceMappingURL=async-replace.d.ts.map