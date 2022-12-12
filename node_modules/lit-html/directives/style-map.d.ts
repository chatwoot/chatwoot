/**
 * @license
 * Copyright 2018 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
import { AttributePart, noChange } from '../lit-html.js';
import { Directive, DirectiveParameters, PartInfo } from '../directive.js';
/**
 * A key-value set of CSS properties and values.
 *
 * The key should be either a valid CSS property name string, like
 * `'background-color'`, or a valid JavaScript camel case property name
 * for CSSStyleDeclaration like `backgroundColor`.
 */
export interface StyleInfo {
    readonly [name: string]: string | undefined | null;
}
declare class StyleMapDirective extends Directive {
    _previousStyleProperties?: Set<string>;
    constructor(partInfo: PartInfo);
    render(styleInfo: StyleInfo): string;
    update(part: AttributePart, [styleInfo]: DirectiveParameters<this>): string | typeof noChange;
}
/**
 * A directive that applies CSS properties to an element.
 *
 * `styleMap` can only be used in the `style` attribute and must be the only
 * expression in the attribute. It takes the property names in the `styleInfo`
 * object and adds the property values as CSS properties. Property names with
 * dashes (`-`) are assumed to be valid CSS property names and set on the
 * element's style object using `setProperty()`. Names without dashes are
 * assumed to be camelCased JavaScript property names and set on the element's
 * style object using property assignment, allowing the style object to
 * translate JavaScript-style names to CSS property names.
 *
 * For example `styleMap({backgroundColor: 'red', 'border-top': '5px', '--size':
 * '0'})` sets the `background-color`, `border-top` and `--size` properties.
 *
 * @param styleInfo
 */
export declare const styleMap: (styleInfo: StyleInfo) => import("../directive.js").DirectiveResult<typeof StyleMapDirective>;
/**
 * The type of the class that powers this directive. Necessary for naming the
 * directive's return type.
 */
export type { StyleMapDirective };
//# sourceMappingURL=style-map.d.ts.map