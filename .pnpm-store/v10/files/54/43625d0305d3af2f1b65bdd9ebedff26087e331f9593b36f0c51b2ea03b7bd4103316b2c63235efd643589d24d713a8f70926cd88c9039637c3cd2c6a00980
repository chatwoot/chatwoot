var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
import { LitElement, html } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';
import { repeat } from 'lit/directives/repeat.js';
import { live } from 'lit/directives/live.js';
import { createRef, ref } from 'lit-html/directives/ref.js';
import { classMap } from 'lit/directives/class-map.js';
import hotkeys from 'hotkeys-js';
import './ninja-header.js';
import './ninja-action.js';
import { footerHtml } from './ninja-footer.js';
import { baseStyles } from './base-styles.js';
let NinjaKeys = class NinjaKeys extends LitElement {
    constructor() {
        super(...arguments);
        /**
         * Search placeholder text
         */
        this.placeholder = 'Type a command or search...';
        /**
         * If true will register all hotkey for all actions
         */
        this.disableHotkeys = false;
        /**
         * Show or hide breadcrumbs on header
         */
        this.hideBreadcrumbs = false;
        /**
         * Open or hide shorcut
         */
        this.openHotkey = 'cmd+k,ctrl+k';
        /**
         * Navigation Up hotkey
         */
        this.navigationUpHotkey = 'up,shift+tab';
        /**
         * Navigation Down hotkey
         */
        this.navigationDownHotkey = 'down,tab';
        /**
         * Close hotkey
         */
        this.closeHotkey = 'esc';
        /**
         * Go back on one level if has parent menu
         */
        this.goBackHotkey = 'backspace';
        /**
         * Select action and execute handler or open submenu
         */
        this.selectHotkey = 'enter'; // enter,space
        /**
         * Show or hide breadcrumbs on header
         */
        this.hotKeysJoinedView = false;
        /**
         * Disable load material icons font on connect
         * If you use custom icons.
         * Set this attribute to prevent load default icons font
         */
        this.noAutoLoadMdIcons = false;
        /**
         * Array of actions
         */
        this.data = [];
        /**
         * Show or hide element
         */
        this.visible = false;
        /**
         * Temproray used for animation effect. TODO: change to animate logic
         */
        this._bump = true;
        this._actionMatches = [];
        this._search = '';
        /**
         * Array of actions in flat structure
         */
        this._flatData = [];
        this._headerRef = createRef();
    }
    /**
     * Public methods
     */
    /**
     * Show a modal
     */
    open(options = {}) {
        this._bump = true;
        this.visible = true;
        this._headerRef.value.focusSearch();
        if (this._actionMatches.length > 0) {
            this._selected = this._actionMatches[0];
        }
        this.setParent(options.parent);
    }
    /**
     * Close modal
     */
    close() {
        this._bump = false;
        this.visible = false;
        // Dispatch close event
        this.dispatchEvent(new CustomEvent('closed', { bubbles: true, composed: true }));
    }
    /**
     * Navigate to group of actions
     * @param parent id of parent group/action
     */
    setParent(parent) {
        if (!parent) {
            this._currentRoot = undefined;
            // this.breadcrumbs = [];
        }
        else {
            this._currentRoot = parent;
        }
        this._selected = undefined;
        this._search = '';
        this._headerRef.value.setSearch('');
    }
    get breadcrumbs() {
        var _a;
        const path = [];
        let parentAction = (_a = this._selected) === null || _a === void 0 ? void 0 : _a.parent;
        if (parentAction) {
            path.push(parentAction);
            while (parentAction) {
                const action = this._flatData.find((a) => a.id === parentAction);
                if (action === null || action === void 0 ? void 0 : action.parent) {
                    path.push(action.parent);
                }
                parentAction = action ? action.parent : undefined;
            }
        }
        return path.reverse();
    }
    connectedCallback() {
        super.connectedCallback();
        if (!this.noAutoLoadMdIcons) {
            document.fonts.load('24px Material Icons', 'apps').then(() => { });
        }
        this._registerInternalHotkeys();
    }
    disconnectedCallback() {
        super.disconnectedCallback();
        this._unregisterInternalHotkeys();
    }
    _flattern(members, parent) {
        let children = [];
        if (!members) {
            members = [];
        }
        return members
            .map((mem) => {
            const alreadyFlatternByUser = mem.children &&
                mem.children.some((value) => {
                    return typeof value == 'string';
                });
            const m = { ...mem, parent: mem.parent || parent };
            if (alreadyFlatternByUser) {
                return m;
            }
            else {
                if (m.children && m.children.length) {
                    parent = mem.id;
                    children = [...children, ...m.children];
                }
                m.children = m.children ? m.children.map((c) => c.id) : [];
                return m;
            }
        })
            .concat(children.length ? this._flattern(children, parent) : children);
    }
    update(changedProperties) {
        if (changedProperties.has('data') && !this.disableHotkeys) {
            this._flatData = this._flattern(this.data);
            this._flatData
                .filter((action) => !!action.hotkey)
                .forEach((action) => {
                hotkeys(action.hotkey, (event) => {
                    event.preventDefault();
                    if (action.handler) {
                        action.handler(action);
                    }
                });
            });
        }
        super.update(changedProperties);
    }
    _registerInternalHotkeys() {
        if (this.openHotkey) {
            hotkeys(this.openHotkey, (event) => {
                event.preventDefault();
                this.visible ? this.close() : this.open();
            });
        }
        if (this.selectHotkey) {
            hotkeys(this.selectHotkey, (event) => {
                if (!this.visible) {
                    return;
                }
                event.preventDefault();
                this._actionSelected(this._actionMatches[this._selectedIndex]);
            });
        }
        if (this.goBackHotkey) {
            hotkeys(this.goBackHotkey, (event) => {
                if (!this.visible) {
                    return;
                }
                if (!this._search) {
                    event.preventDefault();
                    this._goBack();
                }
            });
        }
        if (this.navigationDownHotkey) {
            hotkeys(this.navigationDownHotkey, (event) => {
                if (!this.visible) {
                    return;
                }
                event.preventDefault();
                if (this._selectedIndex >= this._actionMatches.length - 1) {
                    this._selected = this._actionMatches[0];
                }
                else {
                    this._selected = this._actionMatches[this._selectedIndex + 1];
                }
            });
        }
        if (this.navigationUpHotkey) {
            hotkeys(this.navigationUpHotkey, (event) => {
                if (!this.visible) {
                    return;
                }
                event.preventDefault();
                if (this._selectedIndex === 0) {
                    this._selected = this._actionMatches[this._actionMatches.length - 1];
                }
                else {
                    this._selected = this._actionMatches[this._selectedIndex - 1];
                }
            });
        }
        if (this.closeHotkey) {
            hotkeys(this.closeHotkey, () => {
                if (!this.visible) {
                    return;
                }
                this.close();
            });
        }
    }
    _unregisterInternalHotkeys() {
        if (this.openHotkey) {
            hotkeys.unbind(this.openHotkey);
        }
        if (this.selectHotkey) {
            hotkeys.unbind(this.selectHotkey);
        }
        if (this.goBackHotkey) {
            hotkeys.unbind(this.goBackHotkey);
        }
        if (this.navigationDownHotkey) {
            hotkeys.unbind(this.navigationDownHotkey);
        }
        if (this.navigationUpHotkey) {
            hotkeys.unbind(this.navigationUpHotkey);
        }
        if (this.closeHotkey) {
            hotkeys.unbind(this.closeHotkey);
        }
    }
    _actionFocused(index, $event) {
        // this.selectedIndex = index;
        this._selected = index;
        $event.target.ensureInView();
    }
    _onTransitionEnd() {
        this._bump = false;
    }
    _goBack() {
        const parent = this.breadcrumbs.length > 1
            ? this.breadcrumbs[this.breadcrumbs.length - 2]
            : undefined;
        this.setParent(parent);
    }
    render() {
        const classes = {
            bump: this._bump,
            'modal-content': true,
        };
        const menuClasses = {
            visible: this.visible,
            modal: true,
        };
        const actionMatches = this._flatData.filter((action) => {
            var _a;
            const regex = new RegExp(this._search, 'gi');
            const matcher = action.title.match(regex) || ((_a = action.keywords) === null || _a === void 0 ? void 0 : _a.match(regex));
            if (!this._currentRoot && this._search) {
                // global search for items on root
                return matcher;
            }
            return action.parent === this._currentRoot && matcher;
        });
        const sections = actionMatches.reduce((entryMap, e) => entryMap.set(e.section, [...(entryMap.get(e.section) || []), e]), new Map());
        this._actionMatches = [...sections.values()].flat();
        if (this._actionMatches.length > 0 && this._selectedIndex === -1) {
            this._selected = this._actionMatches[0];
        }
        if (this._actionMatches.length === 0) {
            this._selected = undefined;
        }
        const actionsList = (actions) => html ` ${repeat(actions, (action) => action.id, (action) => {
            var _a;
            return html `<ninja-action
            exportparts="ninja-action,ninja-selected,ninja-icon"
            .selected=${live(action.id === ((_a = this._selected) === null || _a === void 0 ? void 0 : _a.id))}
            .hotKeysJoinedView=${this.hotKeysJoinedView}
            @mouseover=${(event) => this._actionFocused(action, event)}
            @actionsSelected=${(event) => this._actionSelected(event.detail)}
            .action=${action}
          ></ninja-action>`;
        })}`;
        const itemTemplates = [];
        sections.forEach((actions, section) => {
            const header = section
                ? html `<div class="group-header">${section}</div>`
                : undefined;
            itemTemplates.push(html `${header}${actionsList(actions)}`);
        });
        return html `
      <div @click=${this._overlayClick} class=${classMap(menuClasses)}>
        <div class=${classMap(classes)} @animationend=${this._onTransitionEnd}>
          <ninja-header
            exportparts="ninja-input,ninja-input-wrapper"
            ${ref(this._headerRef)}
            .placeholder=${this.placeholder}
            .hideBreadcrumbs=${this.hideBreadcrumbs}
            .breadcrumbs=${this.breadcrumbs}
            @change=${this._handleInput}
            @setParent=${(event) => this.setParent(event.detail.parent)}
            @close=${this.close}
          >
          </ninja-header>
          <div class="modal-body">
            <div class="actions-list" part="actions-list">${itemTemplates}</div>
          </div>
          <slot name="footer"> ${footerHtml} </slot>
        </div>
      </div>
    `;
    }
    get _selectedIndex() {
        if (!this._selected) {
            return -1;
        }
        return this._actionMatches.indexOf(this._selected);
    }
    _actionSelected(action) {
        var _a;
        // fire selected event even when action is empty/not selected,
        // so possible handle api search for example
        this.dispatchEvent(new CustomEvent('selected', {
            detail: { search: this._search, action },
            bubbles: true,
            composed: true,
        }));
        if (!action) {
            return;
        }
        if (action.children && ((_a = action.children) === null || _a === void 0 ? void 0 : _a.length) > 0) {
            this._currentRoot = action.id;
            this._search = '';
        }
        this._headerRef.value.setSearch('');
        this._headerRef.value.focusSearch();
        if (action.handler) {
            const result = action.handler(action);
            if (!(result === null || result === void 0 ? void 0 : result.keepOpen)) {
                this.close();
            }
        }
        this._bump = true;
    }
    async _handleInput(event) {
        this._search = event.detail.search;
        await this.updateComplete;
        this.dispatchEvent(new CustomEvent('change', {
            detail: { search: this._search, actions: this._actionMatches },
            bubbles: true,
            composed: true,
        }));
    }
    _overlayClick(event) {
        var _a;
        if ((_a = event.target) === null || _a === void 0 ? void 0 : _a.classList.contains('modal')) {
            this.close();
        }
    }
};
NinjaKeys.styles = [baseStyles];
__decorate([
    property({ type: String })
], NinjaKeys.prototype, "placeholder", void 0);
__decorate([
    property({ type: Boolean })
], NinjaKeys.prototype, "disableHotkeys", void 0);
__decorate([
    property({ type: Boolean })
], NinjaKeys.prototype, "hideBreadcrumbs", void 0);
__decorate([
    property()
], NinjaKeys.prototype, "openHotkey", void 0);
__decorate([
    property()
], NinjaKeys.prototype, "navigationUpHotkey", void 0);
__decorate([
    property()
], NinjaKeys.prototype, "navigationDownHotkey", void 0);
__decorate([
    property()
], NinjaKeys.prototype, "closeHotkey", void 0);
__decorate([
    property()
], NinjaKeys.prototype, "goBackHotkey", void 0);
__decorate([
    property()
], NinjaKeys.prototype, "selectHotkey", void 0);
__decorate([
    property({ type: Boolean })
], NinjaKeys.prototype, "hotKeysJoinedView", void 0);
__decorate([
    property({ type: Boolean })
], NinjaKeys.prototype, "noAutoLoadMdIcons", void 0);
__decorate([
    property({
        type: Array,
        hasChanged() {
            // Forced to trigger changed event always.
            // Because of a lot of framework pattern wrap object with an Observer, like vue2.
            // That's why object passed to web component always same and no render triggered. Issue #9
            return true;
        },
    })
], NinjaKeys.prototype, "data", void 0);
__decorate([
    state()
], NinjaKeys.prototype, "visible", void 0);
__decorate([
    state()
], NinjaKeys.prototype, "_bump", void 0);
__decorate([
    state()
], NinjaKeys.prototype, "_actionMatches", void 0);
__decorate([
    state()
], NinjaKeys.prototype, "_search", void 0);
__decorate([
    state()
], NinjaKeys.prototype, "_currentRoot", void 0);
__decorate([
    state()
], NinjaKeys.prototype, "_flatData", void 0);
__decorate([
    state()
], NinjaKeys.prototype, "breadcrumbs", null);
__decorate([
    state()
], NinjaKeys.prototype, "_selected", void 0);
NinjaKeys = __decorate([
    customElement('ninja-keys')
], NinjaKeys);
export { NinjaKeys };
//# sourceMappingURL=ninja-keys.js.map