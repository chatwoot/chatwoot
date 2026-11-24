import { ref } from 'vue';
import { mount, flushPromises, enableAutoUnmount } from '@vue/test-utils';
import Modal from '../Modal.vue';
import CatalogSheet from 'dashboard/components-next/whatsapp-catalog/CatalogSheet.vue';
import { useIntersectionObserver } from '@vueuse/core';
import {
  loadCatalog,
  loadProductsPage,
  peekCatalog,
  peekProductsPage,
} from 'dashboard/helper/whatsappCatalogCache';
import whatsappCatalogMessages from 'dashboard/api/whatsappCatalogMessages';

vi.mock('dashboard/helper/whatsappCatalogCache', () => ({
  loadCatalog: vi.fn(),
  loadProductsPage: vi.fn(),
  peekCatalog: vi.fn(),
  peekProductsPage: vi.fn(),
}));
vi.mock('@vueuse/core', async importOriginal => ({
  ...(await importOriginal()),
  useIntersectionObserver: vi.fn(),
}));
vi.mock('dashboard/api/whatsappCatalogMessages', () => ({
  default: { create: vi.fn() },
}));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables/useAdmin', () => ({
  useAdmin: () => ({ isAdmin: ref(true) }),
}));

const catalogData = (status = 'ok') => ({
  status,
  catalog_id: 'cat-1',
  collections: [
    { id: 'c1', name: 'Summer', count: 2 },
    { id: 'c2', name: 'Sale', count: 1 },
  ],
});

const product = (n, extra = {}) => ({
  retailer_id: `sku-${n}`,
  name: `Product ${n}`,
  price: `$${n + 1}`,
  image_urls: [],
  description: null,
  url: null,
  collection_ids: [],
  ...extra,
});

const firstPage = () => ({
  status: 'ok',
  next_cursor: 'cur-1',
  products: [
    product(0, {
      name: 'Red Shirt',
      price: '$1',
      image_urls: ['a.jpg'],
      description: 'Soft cotton',
      url: 'https://x.test/0',
      collection_ids: ['c1', 'c2'],
    }),
    product(1, { name: 'Blue Hat', collection_ids: ['c1'] }),
    product(2, { name: 'Green Sock' }),
  ],
});

const ButtonStub = {
  props: ['label', 'disabled'],
  template: '<button :disabled="disabled">{{ label }}</button>',
};

const mountModal = async (props = {}) => {
  const w = mount(Modal, {
    props: { show: true, inboxId: 1, conversationId: 9, ...props },
    global: {
      mocks: {
        $t: (key, params) =>
          params?.max ? `${key} ${params.count} / ${params.max}` : key,
      },
      stubs: {
        Teleport: true,
        Button: ButtonStub,
        'router-link': { template: '<a><slot /></a>' },
      },
    },
  });
  await flushPromises();
  return w;
};

const reachEnd = async () => {
  const [, callback] = useIntersectionObserver.mock.calls[0];
  callback([{ isIntersecting: true }]);
  await flushPromises();
};

const q = (w, id) => w.find(`[data-testid="${id}"]`);
const rows = w => w.findAll('[data-testid="catalog-product-row"]');

enableAutoUnmount(afterEach);

describe('WhatsappCatalog Modal', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.clearAllMocks();
    loadCatalog.mockResolvedValue(catalogData());
    loadProductsPage.mockResolvedValue(firstPage());
    peekCatalog.mockReturnValue(null);
    peekProductsPage.mockReturnValue(null);
  });

  afterEach(() => {
    vi.clearAllTimers();
    vi.useRealTimers();
  });

  it('opens on the products view with every product once', async () => {
    const w = await mountModal();
    expect(q(w, 'catalog-search').exists()).toBe(true);
    expect(q(w, 'catalog-chip-all').exists()).toBe(true);
    expect(q(w, 'catalog-chip-c2').exists()).toBe(true);
    expect(rows(w)).toHaveLength(3);
    expect(w.text().match(/Red Shirt/g)).toHaveLength(1);
    expect(q(w, 'catalog-chip-c1').text()).toBe('Summer (2)');
    expect(loadCatalog).toHaveBeenCalledWith(1, { force: false });
    expect(loadProductsPage).toHaveBeenCalledWith(1, {
      q: '',
      collectionId: null,
      force: false,
    });
  });

  it('loads the next page at the end without duplicates', async () => {
    const w = await mountModal();
    loadProductsPage.mockResolvedValueOnce({
      status: 'ok',
      next_cursor: null,
      products: [product(2), product(3)],
    });
    await reachEnd();
    expect(loadProductsPage).toHaveBeenLastCalledWith(1, {
      after: 'cur-1',
      q: '',
      collectionId: null,
    });
    expect(rows(w)).toHaveLength(4);
    expect(w.text().match(/Product 3/g)).toHaveLength(1);
    await reachEnd();
    expect(loadProductsPage).toHaveBeenCalledTimes(2);
  });

  it('searches on the server once after the debounce', async () => {
    const w = await mountModal();
    loadProductsPage.mockResolvedValue({
      status: 'ok',
      next_cursor: null,
      products: [product(1, { name: 'Blue Hat' })],
    });
    const search = q(w, 'catalog-search');
    await search.setValue('h');
    await search.setValue('hat');
    expect(loadProductsPage).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(400);
    await flushPromises();
    expect(loadProductsPage).toHaveBeenCalledTimes(2);
    expect(loadProductsPage).toHaveBeenLastCalledWith(1, {
      q: 'hat',
      collectionId: null,
      force: false,
    });
    expect(rows(w)).toHaveLength(1);
    loadProductsPage.mockResolvedValue({
      status: 'ok',
      next_cursor: null,
      products: [],
    });
    await search.setValue('zzz');
    await vi.advanceTimersByTimeAsync(400);
    await flushPromises();
    expect(q(w, 'catalog-empty').text()).toBe('CATALOG.SEARCH.NO_RESULTS');
  });

  it('requests the first page of a collection keeping the search', async () => {
    const w = await mountModal();
    await q(w, 'catalog-search').setValue('hat');
    await vi.advanceTimersByTimeAsync(400);
    await q(w, 'catalog-chip-c2').trigger('click');
    expect(loadProductsPage).toHaveBeenLastCalledWith(1, {
      q: 'hat',
      collectionId: 'c2',
      force: false,
    });
  });

  it('keeps the selection across collections and sends it', async () => {
    whatsappCatalogMessages.create.mockResolvedValue({});
    const w = await mountModal({ initialBody: 'Hola' });
    await q(w, 'catalog-select').trigger('click');
    await rows(w)[0].trigger('click');
    loadProductsPage.mockResolvedValue({
      status: 'ok',
      next_cursor: null,
      products: [product(9, { name: 'Other' })],
    });
    await q(w, 'catalog-chip-c2').trigger('click');
    await flushPromises();
    expect(rows(w)).toHaveLength(1);
    expect(q(w, 'catalog-counter').text()).toContain('CATALOG.COUNTER');
    await rows(w)[0].trigger('click');
    await q(w, 'catalog-next').trigger('click');
    await q(w, 'catalog-format-product_list').setValue(true);
    await q(w, 'catalog-send').trigger('click');
    await flushPromises();
    const { products } = whatsappCatalogMessages.create.mock.calls[0][1];
    expect(products.map(p => [p.retailer_id, p.section])).toEqual([
      ['sku-0', 'Summer'],
      ['sku-9', 'CATALOG.NO_COLLECTION'],
    ]);
  });

  it('passes backButton to the sheet only with the detail open', async () => {
    const w = await mountModal();
    const sheet = w.findComponent(CatalogSheet);
    expect(sheet.props('backButton')).toBe(false);
    await rows(w)[0].find('[data-testid="catalog-see-more"]').trigger('click');
    expect(sheet.props('backButton')).toBe(true);
    sheet.vm.$emit('close');
    await flushPromises();
    expect(sheet.props('backButton')).toBe(false);
  });

  it('replaces the list with the detail in the same sheet', async () => {
    const w = await mountModal();
    await rows(w)[0].find('[data-testid="catalog-see-more"]').trigger('click');
    const detail = w.find('[data-test-id="catalog-detail"]');
    expect(detail.exists()).toBe(true);
    expect(detail.text()).toContain('Red Shirt');
    expect(w.findAll('[data-test-id="catalog-sheet"]')).toHaveLength(1);
    expect(q(w, 'catalog-search').isVisible()).toBe(false);
    expect(rows(w)[0].isVisible()).toBe(false);
  });

  it('goes back from the detail keeping search and selection', async () => {
    const w = await mountModal();
    const sheet = w.findComponent(CatalogSheet);
    await q(w, 'catalog-select').trigger('click');
    await rows(w)[0].trigger('click');
    await q(w, 'catalog-search').setValue('red');
    await rows(w)[0].find('[data-testid="catalog-see-more"]').trigger('click');
    sheet.vm.$emit('close');
    await flushPromises();
    expect(w.find('[data-test-id="catalog-detail"]').exists()).toBe(false);
    expect(q(w, 'catalog-search').element.value).toBe('red');
    expect(q(w, 'catalog-search').isVisible()).toBe(true);
    expect(rows(w)).toHaveLength(3);
    expect(rows(w)[0].find('input').element.checked).toBe(true);
    expect(loadProductsPage).toHaveBeenCalledTimes(1);
    expect(w.emitted('close')).toBeFalsy();
    expect(w.emitted('update:show')).toBeFalsy();
    sheet.vm.$emit('close');
    expect(w.emitted('update:show')[0]).toEqual([false]);
    expect(w.emitted('close')).toBeTruthy();
  });

  it('gives the search input the same height as the buttons', async () => {
    const w = await mountModal();
    const search = q(w, 'catalog-search');
    expect(search.classes()).toContain('h-10');
    expect(search.classes()).toContain('!mb-0');
    expect(search.element.parentElement.classList).toContain('items-center');
  });

  it('renders refresh as an icon-only button', async () => {
    const w = await mountModal();
    expect(q(w, 'catalog-refresh').text()).toBe('');
    expect(q(w, 'catalog-refresh').attributes('aria-label')).toBe(
      'CATALOG.ACTIONS.REFRESH'
    );
    expect(w.find('[data-test-id="catalog-sheet-close"]').exists()).toBe(true);
    expect(q(w, 'catalog-counter').exists()).toBe(false);
  });

  it('forces a reload with Refresh', async () => {
    const w = await mountModal();
    await q(w, 'catalog-refresh').trigger('click');
    expect(loadCatalog).toHaveBeenLastCalledWith(1, { force: true });
    expect(loadProductsPage).toHaveBeenLastCalledWith(1, {
      q: '',
      collectionId: null,
      force: true,
    });
  });

  it('disables the carousel with one product and keeps the list', async () => {
    const w = await mountModal();
    expect(q(w, 'catalog-next').exists()).toBe(false);
    await q(w, 'catalog-select').trigger('click');
    expect(q(w, 'catalog-next').element.disabled).toBe(true);
    await rows(w)[0].trigger('click');
    expect(q(w, 'catalog-counter').text()).toContain('CATALOG.COUNTER');
    expect(
      w.find('[data-testid="catalog-next"]').element.parentElement.textContent
    ).not.toContain('CATALOG.COUNTER');
    expect(q(w, 'catalog-cancel-selection').text()).toBe(
      'CATALOG.ACTIONS.CANCEL'
    );
    expect(q(w, 'catalog-next').text()).toBe('CATALOG.ACTIONS.NEXT');
    await q(w, 'catalog-next').trigger('click');
    expect(q(w, 'catalog-format-carousel').element.disabled).toBe(true);
    expect(q(w, 'catalog-format-product_list').element.disabled).toBe(false);
    expect(q(w, 'catalog-format-reason-carousel').exists()).toBe(true);
    expect(q(w, 'catalog-back-link').exists()).toBe(false);
    await q(w, 'catalog-back').trigger('click');
    expect(rows(w)[0].find('input').element.checked).toBe(true);
  });

  it('requires header and body for a list', async () => {
    const w = await mountModal();
    await q(w, 'catalog-select').trigger('click');
    await rows(w)[0].trigger('click');
    await q(w, 'catalog-next').trigger('click');
    await q(w, 'catalog-format-product_list').setValue(true);
    await q(w, 'catalog-field-header').setValue('');
    await q(w, 'catalog-send').trigger('click');
    expect(whatsappCatalogMessages.create).not.toHaveBeenCalled();
    expect(w.text()).toContain('CATALOG.ERRORS.REQUIRED');
  });

  it('sends the expected payload and emits sent', async () => {
    whatsappCatalogMessages.create.mockResolvedValue({});
    const w = await mountModal({ initialBody: 'Hola' });
    await q(w, 'catalog-select').trigger('click');
    await rows(w)[0].trigger('click');
    await rows(w)[2].trigger('click');
    await q(w, 'catalog-next').trigger('click');
    await q(w, 'catalog-format-product_list').setValue(true);
    expect(q(w, 'catalog-field-header').element.value).toBe('Summer');
    await q(w, 'catalog-send').trigger('click');
    await flushPromises();
    expect(whatsappCatalogMessages.create).toHaveBeenCalledWith(9, {
      kind: 'product_list',
      content: 'Hola',
      header: 'Summer',
      footer: '',
      catalog_id: 'cat-1',
      products: [
        {
          retailer_id: 'sku-0',
          name: 'Red Shirt',
          price: '$1',
          description: 'Soft cotton',
          url: 'https://x.test/0',
          section: 'Summer',
          image_urls: ['a.jpg'],
        },
        {
          retailer_id: 'sku-2',
          name: 'Green Sock',
          price: '$3',
          description: null,
          url: null,
          section: 'CATALOG.NO_COLLECTION',
          image_urls: [],
        },
      ],
    });
    expect(w.emitted('sent')).toBeTruthy();
    expect(w.emitted('close')).toBeTruthy();
  });

  it('shows the link button only with a catalog link and emits it', async () => {
    loadCatalog.mockResolvedValue(catalogData());
    const without = await mountModal();
    expect(q(without, 'catalog-insert-link').exists()).toBe(false);

    const w = await mountModal({ catalogLink: 'https://wa.me/c/573001234567' });
    await q(w, 'catalog-insert-link').trigger('click');
    expect(w.emitted('insertLink')[0]).toEqual([
      'https://wa.me/c/573001234567',
    ]);
    expect(w.emitted('update:show')[0]).toEqual([false]);
    expect(w.emitted('close')).toBeTruthy();
    expect(whatsappCatalogMessages.create).not.toHaveBeenCalled();
  });

  it('shows the permission guide mentioning catalog_management', async () => {
    loadCatalog.mockResolvedValue({
      status: 'missing_permission',
      collections: [],
    });
    loadProductsPage.mockResolvedValue({
      status: 'missing_permission',
      products: [],
    });
    const w = await mountModal();
    expect(q(w, 'catalog-setup-guide').text()).toContain(
      'CATALOG.SETUP_GUIDE.MISSING_PERMISSION.TITLE'
    );
    expect(q(w, 'catalog-search').exists()).toBe(false);
  });

  it('shows the setup guide for no_catalog', async () => {
    loadCatalog.mockResolvedValue({
      status: 'no_catalog',
      collections: [],
    });
    loadProductsPage.mockResolvedValue({ status: 'no_catalog', products: [] });
    const w = await mountModal();
    expect(q(w, 'catalog-setup-guide').exists()).toBe(true);
    expect(q(w, 'catalog-search').exists()).toBe(false);
  });

  describe('with prefetched data', () => {
    const mountCached = () =>
      mount(Modal, {
        props: { show: true, inboxId: 1, conversationId: 9 },
        global: {
          mocks: { $t: key => key },
          stubs: { Teleport: true, Button: ButtonStub },
        },
      });

    it('paints fresh data without loading state or requests', async () => {
      peekCatalog.mockReturnValue({ data: catalogData(), isStale: false });
      peekProductsPage.mockReturnValue({ data: firstPage(), isStale: false });
      const w = mountCached();
      expect(rows(w)).toHaveLength(3);
      expect(w.text()).not.toContain('CATALOG.STATES.LOADING');
      await flushPromises();
      expect(w.text()).not.toContain('CATALOG.STATES.LOADING');
      expect(loadCatalog).not.toHaveBeenCalled();
      expect(loadProductsPage).not.toHaveBeenCalled();
    });

    it('paints stale data at once and refreshes it in the background', async () => {
      peekCatalog.mockReturnValue({ data: catalogData(), isStale: true });
      peekProductsPage.mockReturnValue({ data: firstPage(), isStale: true });
      loadProductsPage.mockResolvedValue({
        ...firstPage(),
        products: [...firstPage().products, product(5, { name: 'New Scarf' })],
      });
      const w = mountCached();
      expect(rows(w)).toHaveLength(3);
      expect(w.text()).not.toContain('CATALOG.STATES.LOADING');
      expect(loadCatalog).toHaveBeenCalledWith(1);
      expect(loadProductsPage).toHaveBeenCalledWith(1, {});
      await flushPromises();
      expect(w.text()).not.toContain('CATALOG.STATES.LOADING');
      expect(rows(w)).toHaveLength(4);
      expect(w.text()).toContain('New Scarf');
    });

    it('ignores the background refresh when the user changed collection', async () => {
      peekCatalog.mockReturnValue({ data: catalogData(), isStale: true });
      peekProductsPage.mockReturnValue({ data: firstPage(), isStale: true });
      let resolveBackground;
      loadProductsPage.mockReturnValueOnce(
        new Promise(resolve => {
          resolveBackground = resolve;
        })
      );
      const w = mountCached();
      loadProductsPage.mockResolvedValue({
        status: 'ok',
        next_cursor: null,
        products: [product(9, { name: 'Other' })],
      });
      await q(w, 'catalog-chip-c2').trigger('click');
      await flushPromises();
      resolveBackground({ ...firstPage(), products: [product(5)] });
      await flushPromises();
      expect(rows(w)).toHaveLength(1);
      expect(w.text()).toContain('Other');
    });

    it('keeps the cached list when the background refresh fails', async () => {
      peekCatalog.mockReturnValue({ data: catalogData(), isStale: true });
      peekProductsPage.mockReturnValue({ data: firstPage(), isStale: true });
      loadCatalog.mockRejectedValue(new Error('boom'));
      const w = mountCached();
      await flushPromises();
      expect(rows(w)).toHaveLength(3);
      expect(w.text()).not.toContain('CATALOG.STATES.ERROR');
    });
  });

  it('shows the loading state when nothing is prefetched', async () => {
    loadCatalog.mockReturnValue(new Promise(() => {}));
    loadProductsPage.mockReturnValue(new Promise(() => {}));
    const w = await mountModal();
    expect(w.text()).toContain('CATALOG.STATES.LOADING');
  });

  it('opens the detail with See more without selecting the product', async () => {
    const w = await mountModal();
    const sheet = w.findComponent(CatalogSheet);
    await q(w, 'catalog-select').trigger('click');
    await rows(w)[0].find('[data-testid="catalog-see-more"]').trigger('click');
    expect(w.find('[data-test-id="catalog-detail"]').exists()).toBe(true);
    sheet.vm.$emit('close');
    await flushPromises();
    expect(q(w, 'catalog-counter').text()).toContain('0 / 30');
    expect(q(w, 'catalog-next').element.disabled).toBe(true);
    expect(rows(w)[0].find('input').element.checked).toBe(false);
  });

  it('stops the selection at 30 products', async () => {
    loadProductsPage.mockResolvedValue({
      status: 'ok',
      next_cursor: null,
      products: Array.from({ length: 31 }, (_, n) => product(n)),
    });
    const w = await mountModal();
    await q(w, 'catalog-select').trigger('click');
    for (let n = 0; n < 30; n += 1) {
      // eslint-disable-next-line no-await-in-loop
      await rows(w)[n].trigger('click');
    }
    expect(q(w, 'catalog-counter').text()).toContain('30 / 30');
    await rows(w)[30].trigger('click');
    expect(rows(w)[30].find('input').element.checked).toBe(false);
    expect(rows(w)[30].find('input').element.disabled).toBe(true);
    expect(q(w, 'catalog-counter').text()).toContain('30 / 30');
  });

  it('keeps the selection across pages and searches', async () => {
    const w = await mountModal();
    await q(w, 'catalog-select').trigger('click');
    await rows(w)[0].trigger('click');
    loadProductsPage.mockResolvedValueOnce({
      status: 'ok',
      next_cursor: null,
      products: [product(3)],
    });
    await reachEnd();
    await rows(w)[3].trigger('click');
    expect(q(w, 'catalog-counter').text()).toContain('2 / 30');
    loadProductsPage.mockResolvedValue({
      status: 'ok',
      next_cursor: null,
      products: [product(7)],
    });
    await q(w, 'catalog-search').setValue('x');
    await vi.advanceTimersByTimeAsync(400);
    await flushPromises();
    expect(rows(w)).toHaveLength(1);
    expect(q(w, 'catalog-counter').text()).toContain('2 / 30');
    await rows(w)[0].trigger('click');
    expect(q(w, 'catalog-counter').text()).toContain('3 / 30');
  });

  it('ignores a slow catalog response after the dialog was reopened for another inbox', async () => {
    let resolveSlow;
    loadCatalog.mockReturnValueOnce(
      new Promise(resolve => {
        resolveSlow = resolve;
      })
    );
    loadCatalog.mockResolvedValue({
      ...catalogData(),
      collections: [{ id: 'c9', name: 'Other inbox', count: 1 }],
    });
    const w = await mountModal();
    await w.setProps({ show: false });
    await w.setProps({ show: true, inboxId: 2 });
    await flushPromises();

    resolveSlow(catalogData());
    await flushPromises();

    expect(q(w, 'catalog-chip-c9').exists()).toBe(true);
    expect(q(w, 'catalog-chip-c1').exists()).toBe(false);
  });
});
