/**
 * @license
 * Copyright 2018 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
import { AttributePart, noChange } from '../lit-html.js';
import { Directive, DirectiveParameters, PartInfo } from '../directive.js';
/**
 * A key-value set of class names to truthy values.
 */
export interface ClassInfo {
    readonly [name: string]: string | boolean | number;
}
declare class ClassMapDirective extends Directive {
    /**
     * Stores the ClassInfo object applied to a given AttributePart.
     * Used to unset existing values when a new ClassInfo object is applied.
     */
    private _previousClasses?;
    private _staticClasses?;
    constructor(partInfo: PartInfo);
    render(classInfo: ClassInfo): string;
    update(part: AttributePart, [classInfo]: DirectiveParameters<this>): string | typeof noChange;
}
/**
 * A directive that applies dynamic CSS classes.
 *
 * This must be used in the `class` attribute and must be the only part used in
 * the attribute. It takes each property in the `classInfo` argument and adds
 * the property name to the element's `classList` if the property value is
 * truthy; if the property value is falsey, the property name is removed from
 * the element's `class`.
 *
 * For example `{foo: bar}` applies the class `foo` if the value of `bar` is
 * truthy.
 *
 * @param classInfo
 */
export declare const classMap: (classInfo: ClassInfo) => import("../directive.js").DirectiveResult<typeof ClassMapDirective>;
/**
 * The type of the class that powers this directive. Necessary for naming the
 * directive's return type.
 */
export type { ClassMapDirective };
//# sourceMappingURL=class-map.d.ts.map