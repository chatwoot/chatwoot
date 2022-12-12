/**
 * @license
 * Copyright 2018 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { __decorate } from "tslib";
// Style preference for leading underscores.
// tslint:disable:strip-private-property-underscore
import { html, LitElement } from 'lit';
import { customElement } from 'lit/decorators.js';
import { styles } from './mwc-icon-host.css';
/** @soyCompatible */
let Icon = class Icon extends LitElement {
    /** @soyTemplate */
    render() {
        return html `<span><slot></slot></span>`;
    }
};
Icon.styles = [styles];
Icon = __decorate([
    customElement('mwc-icon')
], Icon);
export { Icon };
//# sourceMappingURL=mwc-icon.js.map