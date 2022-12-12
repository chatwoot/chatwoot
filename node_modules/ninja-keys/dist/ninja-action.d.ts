import { LitElement } from 'lit';
import '@material/mwc-icon';
import { INinjaAction } from './interfaces/ininja-action.js';
export declare class NinjaAction extends LitElement {
    static styles: import("lit").CSSResult;
    action: INinjaAction;
    selected: boolean;
    /**
     * Display hotkey as separate buttons on UI or as is
     */
    hotKeysJoinedView: boolean;
    /**
     * Scroll to show element
     */
    ensureInView(): void;
    click(): void;
    constructor();
    updated(changedProperties: Map<string, unknown>): void;
    render(): import("lit-html").TemplateResult<1>;
}
declare global {
    interface HTMLElementTagNameMap {
        'ninja-action': NinjaAction;
    }
}
//# sourceMappingURL=ninja-action.d.ts.map