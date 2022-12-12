/**
 * @license
 * Copyright 2020 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
import { ElementPart } from '../lit-html.js';
import { AsyncDirective } from '../async-directive.js';
/**
 * Creates a new Ref object, which is container for a reference to an element.
 */
export declare const createRef: <T = Element>() => Ref<T>;
/**
 * An object that holds a ref value.
 */
declare class Ref<T = Element> {
    /**
     * The current Element value of the ref, or else `undefined` if the ref is no
     * longer rendered.
     */
    readonly value?: T;
}
export type { Ref };
export declare type RefOrCallback = Ref | ((el: Element | undefined) => void);
declare class RefDirective extends AsyncDirective {
    private _element?;
    private _ref?;
    private _context;
    render(_ref: RefOrCallback): symbol;
    update(part: ElementPart, [ref]: Parameters<this['render']>): symbol;
    private _updateRefValue;
    private get _lastElementForRef();
    disconnected(): void;
    reconnected(): void;
}
/**
 * Sets the value of a Ref object or calls a ref callback with the element it's
 * bound to.
 *
 * A Ref object acts as a container for a reference to an element. A ref
 * callback is a function that takes an element as its only argument.
 *
 * The ref directive sets the value of the Ref object or calls the ref callback
 * during rendering, if the referenced element changed.
 *
 * Note: If a ref callback is rendered to a different element position or is
 * removed in a subsequent render, it will first be called with `undefined`,
 * followed by another call with the new element it was rendered to (if any).
 *
 * ```js
 * // Using Ref object
 * const inputRef = createRef();
 * render(html`<input ${ref(inputRef)}>`, container);
 * inputRef.value.focus();
 *
 * // Using callback
 * const callback = (inputElement) => inputElement.focus();
 * render(html`<input ${ref(callback)}>`, container);
 * ```
 */
export declare const ref: (_ref: RefOrCallback) => import("../directive.js").DirectiveResult<typeof RefDirective>;
/**
 * The type of the class that powers this directive. Necessary for naming the
 * directive's return type.
 */
export type { RefDirective };
//# sourceMappingURL=ref.d.ts.map