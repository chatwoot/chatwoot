import {LitElement, html, css, TemplateResult} from 'lit';
import {customElement, property} from 'lit/decorators.js';
import {ref, createRef} from 'lit/directives/ref.js';

@customElement('ninja-header')
export class NinjaHeader extends LitElement {
  static override styles = css`
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

  @property()
  placeholder = '';

  @property({type: Boolean})
  hideBreadcrumbs = false;

  @property()
  breadcrumbHome = 'Home';

  @property({type: Array})
  breadcrumbs: string[] = [];

  private _inputRef = createRef<HTMLInputElement>();

  override render() {
    let breadcrumbs: TemplateResult<1> | '' = '';
    if (!this.hideBreadcrumbs) {
      const itemTemplates = [];
      for (const breadcrumb of this.breadcrumbs) {
        itemTemplates.push(
          html`<button
            tabindex="-1"
            @click=${() => this.selectParent(breadcrumb)}
            class="breadcrumb"
          >
            ${breadcrumb}
          </button>`
        );
      }
      breadcrumbs = html`<div class="breadcrumb-list">
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

    return html`
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

  setSearch(value: string) {
    if (this._inputRef.value) {
      this._inputRef.value.value = value;
    }
  }

  focusSearch() {
    requestAnimationFrame(() => this._inputRef.value!.focus());
  }

  private _handleInput(event: Event) {
    const input = event.target as HTMLInputElement;
    this.dispatchEvent(
      new CustomEvent('change', {
        detail: {search: input.value},
        bubbles: false,
        composed: false,
      })
    );
  }

  private selectParent(breadcrumb?: string) {
    this.dispatchEvent(
      new CustomEvent('setParent', {
        detail: {parent: breadcrumb},
        bubbles: true,
        composed: true,
      })
    );
  }

  override firstUpdated() {
    this.focusSearch();
  }

  _close() {
    this.dispatchEvent(
      new CustomEvent('close', {bubbles: true, composed: true})
    );
  }
}

declare global {
  interface HTMLElementTagNameMap {
    'ninja-header': NinjaHeader;
  }
}
