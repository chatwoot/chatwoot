/**
 * @license
 * Copyright 2019 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
import type { TemplateResult } from './lit-html.js';
import { RenderOptions } from './lit-html.js';
/**
 * hydrate() operates on a container with server-side rendered content and
 * restores the client side data structures needed for lit-html updates such as
 * TemplateInstances and Parts. After calling `hydrate`, lit-html will behave as
 * if it initially rendered the DOM, and any subsequent updates will update
 * efficiently, the same as if lit-html had rendered the DOM on the client.
 *
 * hydrate() must be called on DOM that adheres the to lit-ssr structure for
 * parts. ChildParts must be represented with both a start and end comment
 * marker, and ChildParts that contain a TemplateInstance must have the template
 * digest written into the comment data.
 *
 * Since render() encloses its output in a ChildPart, there must always be a root
 * ChildPart.
 *
 * Example (using for # ... for annotations in HTML)
 *
 * Given this input:
 *
 *   html`<div class=${x}>${y}</div>`
 *
 * The SSR DOM is:
 *
 *   <!--lit-part AEmR7W+R0Ak=-->  # Start marker for the root ChildPart created
 *                                 # by render(). Includes the digest of the
 *                                 # template
 *   <div class="TEST_X">
 *     <!--lit-node 0--> # Indicates there are attribute bindings here
 *                           # The number is the depth-first index of the parent
 *                           # node in the template.
 *     <!--lit-part-->  # Start marker for the ${x} expression
 *     TEST_Y
 *     <!--/lit-part-->  # End marker for the ${x} expression
 *   </div>
 *
 *   <!--/lit-part-->  # End marker for the root ChildPart
 *
 * @param rootValue
 * @param container
 * @param userOptions
 */
export declare const hydrate: (rootValue: unknown, container: Element | DocumentFragment, options?: Partial<RenderOptions>) => void;
export declare const digestForTemplateResult: (templateResult: TemplateResult) => string;
//# sourceMappingURL=experimental-hydrate.d.ts.map