import { LitElement, TemplateResult, PropertyValues } from 'lit';
import './ninja-header.js';
import './ninja-action.js';
import { INinjaAction } from './interfaces/ininja-action.js';
export declare class NinjaKeys extends LitElement {
    static styles: import("lit").CSSResult[];
    /**
     * Search placeholder text
     */
    placeholder: string;
    /**
     * If true will register all hotkey for all actions
     */
    disableHotkeys: boolean;
    /**
     * Show or hide breadcrumbs on header
     */
    hideBreadcrumbs: boolean;
    /**
     * Open or hide shorcut
     */
    openHotkey: string;
    /**
     * Navigation Up hotkey
     */
    navigationUpHotkey: string;
    /**
     * Navigation Down hotkey
     */
    navigationDownHotkey: string;
    /**
     * Close hotkey
     */
    closeHotkey: string;
    /**
     * Go back on one level if has parent menu
     */
    goBackHotkey: string;
    /**
     * Select action and execute handler or open submenu
     */
    selectHotkey: string;
    /**
     * Show or hide breadcrumbs on header
     */
    hotKeysJoinedView: boolean;
    /**
     * Disable load material icons font on connect
     * If you use custom icons.
     * Set this attribute to prevent load default icons font
     */
    noAutoLoadMdIcons: boolean;
    /**
     * Array of actions
     */
    data: INinjaAction[];
    /**
     * Public methods
     */
    /**
     * Show a modal
     */
    open(options?: {
        parent?: string;
    }): void;
    /**
     * Close modal
     */
    close(): void;
    /**
     * Navigate to group of actions
     * @param parent id of parent group/action
     */
    setParent(parent?: string): void;
    /**
     * Show or hide element
     */
    visible: boolean;
    /**
     * Temproray used for animation effect. TODO: change to animate logic
     */
    private _bump;
    private _actionMatches;
    private _search;
    private _currentRoot?;
    /**
     * Array of actions in flat structure
     */
    _flatData: INinjaAction[];
    private get breadcrumbs();
    private _selected?;
    connectedCallback(): void;
    disconnectedCallback(): void;
    private _flattern;
    update(changedProperties: PropertyValues<this>): void;
    private _registerInternalHotkeys;
    private _unregisterInternalHotkeys;
    private _actionFocused;
    private _onTransitionEnd;
    private _goBack;
    private _headerRef;
    render(): TemplateResult<1>;
    private get _selectedIndex();
    private _actionSelected;
    private _handleInput;
    private _overlayClick;
}
declare global {
    interface HTMLElementTagNameMap {
        'ninja-keys': NinjaKeys;
    }
}
//# sourceMappingURL=ninja-keys.d.ts.map