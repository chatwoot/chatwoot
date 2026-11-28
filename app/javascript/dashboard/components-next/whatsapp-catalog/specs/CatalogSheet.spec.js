import { mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import CatalogSheet from '../CatalogSheet.vue';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: { en: { CATALOG: { ACTIONS: { CLOSE: 'Close', BACK: 'Back' } } } },
});

const mountSheet = (props = { show: true, title: 'Details' }, slots = {}) =>
  mount(CatalogSheet, {
    props,
    slots: { default: '<p>Body</p>', ...slots },
    attachTo: document.body,
    global: {
      plugins: [i18n],
      stubs: {
        SheetHandle: {
          emits: ['close'],
          template: '<div data-test-id="handle" @click="$emit(\'close\')" />',
        },
      },
    },
  });

const q = selector => document.body.querySelector(selector);

describe('CatalogSheet', () => {
  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('renders nothing when hidden', () => {
    const wrapper = mountSheet({ show: false, title: 'Details' });
    expect(q('[data-test-id="catalog-sheet"]')).toBeNull();
    wrapper.unmount();
  });

  it('renders title, body and footer slot with a round close button at the end', () => {
    const wrapper = mountSheet(undefined, { footer: '<span>Foot</span>' });
    const header = q('[data-test-id="catalog-sheet-header"]');
    expect(header.textContent).toContain('Details');
    expect(header.lastElementChild.getAttribute('aria-label')).toBe('Close');
    expect(q('[data-test-id="catalog-sheet"]').textContent).toContain('Body');
    expect(q('[data-test-id="catalog-sheet"]').textContent).toContain('Foot');
    wrapper.unmount();
  });

  it('renders the drag handle as first child of the sheet', () => {
    const wrapper = mountSheet();
    expect(q('[data-test-id="catalog-sheet"]').firstElementChild).toBe(
      q('[data-test-id="handle"]')
    );
    wrapper.unmount();
  });

  it('emits close when the handle is dragged down', () => {
    const wrapper = mountSheet();
    q('[data-test-id="handle"]').click();
    expect(wrapper.emitted('close')).toHaveLength(1);
    wrapper.unmount();
  });

  it('emits close from the X button', () => {
    const wrapper = mountSheet();
    q('[data-test-id="catalog-sheet-close"]').click();
    expect(wrapper.emitted('close')).toHaveLength(1);
    wrapper.unmount();
  });

  it('shows a mobile-only back arrow before the title with backButton', () => {
    const wrapper = mountSheet({
      show: true,
      title: 'Details',
      backButton: true,
    });
    const header = q('[data-test-id="catalog-sheet-header"]');
    const back = q('[data-test-id="catalog-sheet-back"]');
    expect(header.firstElementChild).toBe(back);
    expect(back.getAttribute('aria-label')).toBe('Back');
    expect(back.className).toContain('sm:hidden');
    back.click();
    expect(wrapper.emitted('close')).toHaveLength(1);
    wrapper.unmount();
  });

  it('keeps the X at the end on desktop with backButton', () => {
    const wrapper = mountSheet({
      show: true,
      title: 'Details',
      backButton: true,
    });
    const close = q('[data-test-id="catalog-sheet-close"]');
    expect(q('[data-test-id="catalog-sheet-header"]').lastElementChild).toBe(
      close
    );
    expect(close.className).toContain('max-sm:hidden');
    wrapper.unmount();
  });

  it('does not render the back arrow without backButton', () => {
    const wrapper = mountSheet();
    expect(q('[data-test-id="catalog-sheet-back"]')).toBeNull();
    wrapper.unmount();
  });

  it('emits close on Escape', () => {
    const wrapper = mountSheet();
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    expect(wrapper.emitted('close')).toHaveLength(1);
    wrapper.unmount();
  });

  it('emits close when clicking the backdrop but not the sheet', () => {
    const wrapper = mountSheet();
    q('[data-test-id="catalog-sheet"]').click();
    expect(wrapper.emitted('close')).toBeUndefined();
    q('[data-test-id="catalog-sheet-backdrop"]').click();
    expect(wrapper.emitted('close')).toHaveLength(1);
    wrapper.unmount();
  });

  it('does not let the backdrop click reach the element below', () => {
    const wrapper = mountSheet();
    const parentClick = vi.fn();
    document.body.addEventListener('click', parentClick);
    const event = new MouseEvent('click', { bubbles: true, cancelable: true });
    q('[data-test-id="catalog-sheet-backdrop"]').dispatchEvent(event);
    expect(wrapper.emitted('close')).toHaveLength(1);
    expect(event.defaultPrevented).toBe(true);
    expect(parentClick).not.toHaveBeenCalled();
    document.body.removeEventListener('click', parentClick);
    wrapper.unmount();
  });
});
