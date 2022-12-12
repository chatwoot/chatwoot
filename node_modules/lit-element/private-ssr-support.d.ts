/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
/**
 * END USERS SHOULD NOT RELY ON THIS OBJECT.
 *
 * We currently do not make a mangled rollup build of the lit-ssr code. In order
 * to keep a number of (otherwise private) top-level exports  mangled in the
 * client side code, we export a _$LE object containing those members (or
 * helper methods for accessing private fields of those members), and then
 * re-export them for use in lit-ssr. This keeps lit-ssr agnostic to whether the
 * client-side code is being used in `dev` mode or `prod` mode.
 *
 * @private
 */
export declare const _$LE: {
    attributeToProperty: (el: import("./lit-element.js").LitElement, name: string, value: string | null) => void;
    changedProperties: (el: import("./lit-element.js").LitElement) => any;
};
//# sourceMappingURL=private-ssr-support.d.ts.map