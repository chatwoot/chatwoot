/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
import { ChildPart } from '../lit-html.js';
import { Directive, DirectiveParameters, PartInfo } from '../directive.js';
declare class CacheDirective extends Directive {
    private _templateCache;
    private _value?;
    constructor(partInfo: PartInfo);
    render(v: unknown): unknown[];
    update(containerPart: ChildPart, [v]: DirectiveParameters<this>): unknown[];
}
/**
 * Enables fast switching between multiple templates by caching the DOM nodes
 * and TemplateInstances produced by the templates.
 *
 * Example:
 *
 * ```js
 * let checked = false;
 *
 * html`
 *   ${cache(checked ? html`input is checked` : html`input is not checked`)}
 * `
 * ```
 */
export declare const cache: (v: unknown) => import("../directive.js").DirectiveResult<typeof CacheDirective>;
/**
 * The type of the class that powers this directive. Necessary for naming the
 * directive's return type.
 */
export type { CacheDirective };
//# sourceMappingURL=cache.d.ts.map