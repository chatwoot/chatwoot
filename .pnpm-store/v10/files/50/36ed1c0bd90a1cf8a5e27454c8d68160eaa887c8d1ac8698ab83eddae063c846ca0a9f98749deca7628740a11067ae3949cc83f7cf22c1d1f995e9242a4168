/**
 * @license
 * Copyright 2020 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
import { html as coreHtml, svg as coreSvg, TemplateResult } from './lit-html.js';
export interface StaticValue {
    /** The value to interpolate as-is into the template. */
    _$litStatic$: string;
    /**
     * A value that can't be decoded from ordinary JSON, make it harder for
     * a attacker-controlled data that goes through JSON.parse to produce a valid
     * StaticValue.
     */
    r: typeof brand;
}
/**
 * Prevents JSON injection attacks.
 *
 * The goals of this brand:
 *   1) fast to check
 *   2) code is small on the wire
 *   3) multiple versions of Lit in a single page will all produce mutually
 *      interoperable StaticValues
 *   4) normal JSON.parse (without an unusual reviver) can not produce a
 *      StaticValue
 *
 * Symbols satisfy (1), (2), and (4). We use Symbol.for to satisfy (3), but
 * we don't care about the key, so we break ties via (2) and use the empty
 * string.
 */
declare const brand: unique symbol;
/**
 * Wraps a string so that it behaves like part of the static template
 * strings instead of a dynamic value.
 *
 * Users must take care to ensure that adding the static string to the template
 * results in well-formed HTML, or else templates may break unexpectedly.
 *
 * Note that this function is unsafe to use on untrusted content, as it will be
 * directly parsed into HTML. Do not pass user input to this function
 * without sanitizing it.
 *
 * Static values can be changed, but they will cause a complete re-render
 * since they effectively create a new template.
 */
export declare const unsafeStatic: (value: string) => StaticValue;
/**
 * Tags a string literal so that it behaves like part of the static template
 * strings instead of a dynamic value.
 *
 * The only values that may be used in template expressions are other tagged
 * `literal` results or `unsafeStatic` values (note that untrusted content
 * should never be passed to `unsafeStatic`).
 *
 * Users must take care to ensure that adding the static string to the template
 * results in well-formed HTML, or else templates may break unexpectedly.
 *
 * Static values can be changed, but they will cause a complete re-render since
 * they effectively create a new template.
 */
export declare const literal: (strings: TemplateStringsArray, ...values: unknown[]) => StaticValue;
/**
 * Wraps a lit-html template tag (`html` or `svg`) to add static value support.
 */
export declare const withStatic: (coreTag: typeof coreHtml | typeof coreSvg) => (strings: TemplateStringsArray, ...values: unknown[]) => TemplateResult;
/**
 * Interprets a template literal as an HTML template that can efficiently
 * render to and update a container.
 *
 * Includes static value support from `lit-html/static.js`.
 */
export declare const html: (strings: TemplateStringsArray, ...values: unknown[]) => TemplateResult;
/**
 * Interprets a template literal as an SVG template that can efficiently
 * render to and update a container.
 *
 * Includes static value support from `lit-html/static.js`.
 */
export declare const svg: (strings: TemplateStringsArray, ...values: unknown[]) => TemplateResult;
export {};
//# sourceMappingURL=static.d.ts.map