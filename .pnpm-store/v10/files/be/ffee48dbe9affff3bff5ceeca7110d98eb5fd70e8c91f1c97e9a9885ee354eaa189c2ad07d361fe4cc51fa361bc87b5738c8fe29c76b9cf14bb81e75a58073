var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
import { LitElement, html, css } from 'lit';
import { customElement, property } from 'lit/decorators.js';
import { ref, createRef } from 'lit/directives/ref.js';
let NinjaHeader = class NinjaHeader extends LitElement {
    constructor() {
        super(...arguments);
        this.placeholder = '';
        this.hideBreadcrumbs = false;
        this.breadcrumbHome = 'Home';
        this.breadcrumbs = [];
        this._inputRef = createRef();
    }
    render() {
        let breadcrumbs = '';
        if (!this.hideBreadcrumbs) {
            const itemTemplates = [];
            for (const breadcrumb of this.breadcrumbs) {
                itemTemplates.push(html `<button
            tabindex="-1"
            @click=${() => this.selectParent(breadcrumb)}
            class="breadcrumb"
          >
            ${breadcrumb}
          </button>`);
            }
            breadcrumbs = html `<div class="breadcrumb-list">
        <button
          tabindex="-1"
          @click=${() => this.selectParent()}
          class="breadcrumb"
        >
          ${this.breadcrumbHome}
        </button>
        ${itemTemplates}
      </div>`;
        }
        return html `
      ${breadcrumbs}
      <div part="ninja-input-wrapper" class="search-wrapper">
        <input
          part="ninja-input"
          type="text"
          id="search"
          spellcheck="false"
          autocomplete="off"
          @input="${this._handleInput}"
          ${ref(this._inputRef)}
          placeholder="${this.placeholder}"
          class="search"
        />
      </div>
    `;
    }
    setSearch(value) {
        if (this._inputRef.value) {
            this._inputRef.value.value = value;
        }
    }
    focusSearch() {
        requestAnimationFrame(() => this._inputRef.value.focus());
    }
    _handleInput(event) {
        const input = event.target;
        this.dispatchEvent(new CustomEvent('change', {
            detail: { search: input.value },
            bubbles: false,
            composed: false,
        }));
    }
    selectParent(breadcrumb) {
        this.dispatchEvent(new CustomEvent('setParent', {
            detail: { parent: breadcrumb },
            bubbles: true,
            composed: true,
        }));
    }
    firstUpdated() {
        this.focusSearch();
    }
    _close() {
        this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
    }
};
NinjaHeader.styles = css `
    :host {
      flex: 1;
      position: relative;
    }
    .search {
      padding: 1.25em;
      flex-grow: 1;
      flex-shrink: 0;
      margin: 0px;
      border: none;
      appearance: none;
      font-size: 1.125em;
      background: transparent;
      caret-color: var(--ninja-accent-color);
      color: var(--ninja-text-color);
      outline: none;
      font-family: var(--ninja-font-family);
    }
    .search::placeholder {
      color: var(--ninja-placeholder-color);
    }
    .breadcrumb-list {
      padding: 1em 4em 0 1em;
      display: flex;
      flex-direction: row;
      align-items: stretch;
      justify-content: flex-start;
      flex: initial;
    }

    .breadcrumb {
      background: var(--ninja-secondary-background-color);
      text-align: center;
      line-height: 1.2em;
      border-radius: var(--ninja-key-border-radius);
      border: 0;
      cursor: pointer;
      padding: 0.1em 0.5em;
      color: var(--ninja-secondary-text-color);
      margin-right: 0.5em;
      outline: none;
      font-family: var(--ninja-font-family);
    }

    .search-wrapper {
      display: flex;
      border-bottom: var(--ninja-separate-border);
    }
  `;
__decorate([
    property()
], NinjaHeader.prototype, "placeholder", void 0);
__decorate([
    property({ type: Boolean })
], NinjaHeader.prototype, "hideBreadcrumbs", void 0);
__decorate([
    property()
], NinjaHeader.prototype, "breadcrumbHome", void 0);
__decorate([
    property({ type: Array })
], NinjaHeader.prototype, "breadcrumbs", void 0);
NinjaHeader = __decorate([
    customElement('ninja-header')
], NinjaHeader);
export { NinjaHeader };
//# sourceMappingURL=ninja-header.js.map