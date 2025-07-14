/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
/**
 * Options for the {@linkcode queryAssignedNodes} decorator. Extends the options
 * that can be passed into [HTMLSlotElement.assignedNodes](https://developer.mozilla.org/en-US/docs/Web/API/HTMLSlotElement/assignedNodes).
 */
export interface QueryAssignedNodesOptions extends AssignedNodesOptions {
    /**
     * Name of the slot to query. Leave empty for the default slot.
     */
    slot?: string;
}
declare type TSDecoratorReturnType = void | any;
/**
 * A property decorator that converts a class property into a getter that
 * returns the `assignedNodes` of the given `slot`.
 *
 * Can be passed an optional {@linkcode QueryAssignedNodesOptions} object.
 *
 * Example usage:
 * ```ts
 * class MyElement {
 *   @queryAssignedNodes({slot: 'list', flatten: true})
 *   listItems!: Array<Node>;
 *
 *   render() {
 *     return html`
 *       <slot name="list"></slot>
 *     `;
 *   }
 * }
 * ```
 *
 * Note the type of this property should be annotated as `Array<Node>`.
 *
 * @category Decorator
 */
export declare function queryAssignedNodes(options?: QueryAssignedNodesOptions): TSDecoratorReturnType;
/**
 * A property decorator that converts a class property into a getter that
 * returns the `assignedNodes` of the given named `slot`.
 *
 * Example usage:
 * ```ts
 * class MyElement {
 *   @queryAssignedNodes('list', true, '.item')
 *   listItems!: Array<HTMLElement>;
 *
 *   render() {
 *     return html`
 *       <slot name="list"></slot>
 *     `;
 *   }
 * }
 * ```
 *
 * Note the type of this property should be annotated as `Array<Node>` if used
 * without a `selector` or `Array<HTMLElement>` if a selector is provided.
 * Use {@linkcode queryAssignedElements @queryAssignedElements} to list only
 * elements, and optionally filter the element list using a CSS selector.
 *
 * @param slotName A string name of the slot.
 * @param flatten A boolean which when true flattens the assigned nodes,
 *     meaning any assigned nodes that are slot elements are replaced with their
 *     assigned nodes.
 * @param selector A CSS selector used to filter the elements returned.
 *
 * @category Decorator
 * @deprecated Prefer passing in a single options object, i.e. `{slot: 'list'}`.
 * If using `selector` please use `@queryAssignedElements`.
 * `@queryAssignedNodes('', false, '.item')` is functionally identical to
 * `@queryAssignedElements({slot: '', flatten: false, selector: '.item'})` or
 * `@queryAssignedElements({selector: '.item'})`.
 */
export declare function queryAssignedNodes(slotName?: string, flatten?: boolean, selector?: string): TSDecoratorReturnType;
export {};
//# sourceMappingURL=query-assigned-nodes.d.ts.map