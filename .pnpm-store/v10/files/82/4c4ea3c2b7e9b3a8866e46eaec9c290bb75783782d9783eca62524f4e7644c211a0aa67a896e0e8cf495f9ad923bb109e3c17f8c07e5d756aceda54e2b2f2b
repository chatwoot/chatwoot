/**
 * @license
 * Copyright 2019 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
/**
 * Whether the current browser supports `adoptedStyleSheets`.
 */
export declare const supportsAdoptingStyleSheets: boolean;
/**
 * A CSSResult or native CSSStyleSheet.
 *
 * In browsers that support constructible CSS style sheets, CSSStyleSheet
 * object can be used for styling along side CSSResult from the `css`
 * template tag.
 */
export declare type CSSResultOrNative = CSSResult | CSSStyleSheet;
export declare type CSSResultArray = Array<CSSResultOrNative | CSSResultArray>;
/**
 * A single CSSResult, CSSStyleSheet, or an array or nested arrays of those.
 */
export declare type CSSResultGroup = CSSResultOrNative | CSSResultArray;
/**
 * A container for a string of CSS text, that may be used to create a CSSStyleSheet.
 *
 * CSSResult is the return value of `css`-tagged template literals and
 * `unsafeCSS()`. In order to ensure that CSSResults are only created via the
 * `css` tag and `unsafeCSS()`, CSSResult cannot be constructed directly.
 */
export declare class CSSResult {
    ['_$cssResult$']: boolean;
    readonly cssText: string;
    private _styleSheet?;
    private _strings;
    private constructor();
    get styleSheet(): CSSStyleSheet | undefined;
    toString(): string;
}
/**
 * Wrap a value for interpolation in a {@linkcode css} tagged template literal.
 *
 * This is unsafe because untrusted CSS text can be used to phone home
 * or exfiltrate data to an attacker controlled site. Take care to only use
 * this with trusted input.
 */
export declare const unsafeCSS: (value: unknown) => CSSResult;
/**
 * A template literal tag which can be used with LitElement's
 * {@linkcode LitElement.styles} property to set element styles.
 *
 * For security reasons, only literal string values and number may be used in
 * embedded expressions. To incorporate non-literal values {@linkcode unsafeCSS}
 * may be used inside an expression.
 */
export declare const css: (strings: TemplateStringsArray, ...values: (CSSResultGroup | number)[]) => CSSResult;
/**
 * Applies the given styles to a `shadowRoot`. When Shadow DOM is
 * available but `adoptedStyleSheets` is not, styles are appended to the
 * `shadowRoot` to [mimic spec behavior](https://wicg.github.io/construct-stylesheets/#using-constructed-stylesheets).
 * Note, when shimming is used, any styles that are subsequently placed into
 * the shadowRoot should be placed *before* any shimmed adopted styles. This
 * will match spec behavior that gives adopted sheets precedence over styles in
 * shadowRoot.
 */
export declare const adoptStyles: (renderRoot: ShadowRoot, styles: Array<CSSResultOrNative>) => void;
export declare const getCompatibleStyle: (s: CSSResultOrNative) => CSSResultOrNative;
//# sourceMappingURL=css-tag.d.ts.map