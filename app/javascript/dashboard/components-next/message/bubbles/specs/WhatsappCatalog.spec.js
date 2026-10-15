import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import { createStore } from 'vuex';
import WhatsappCatalog from '../WhatsappCatalog.vue';
import { provideMessageContext } from '../../provider.js';
import en from 'dashboard/i18n/locale/en/conversation.json';

const items = [
  {
    retailerId: 'a',
    name: 'Mug',
    price: '$ 5.000',
    imageUrls: ['https://x/1.jpg', 'https://x/2.jpg'],
    description: 'Ceramic mug',
    url: 'https://x/mug',
    section: 'Kitchen',
  },
  {
    retailerId: 'b',
    name: 'Plate',
    price: '$ 7.000',
    imageUrls: [],
    description: null,
    url: null,
    section: 'Kitchen',
  },
  {
    retailerId: 'c',
    name: 'Bowl',
    price: '$ 3.000',
    imageUrls: [],
    description: null,
    url: null,
    section: 'Kitchen',
  },
];

const mountCatalog = (kind, catalogItems = items) => {
  const TestHost = defineComponent({
    components: { WhatsappCatalog },
    setup() {
      provideMessageContext({
        content: ref('Body text'),
        contentAttributes: ref({
          whatsappCatalog: {
            kind,
            catalogId: '1',
            header: 'Head',
            footer: 'Foot',
            items: catalogItems,
          },
        }),
      });
    },
    template: '<WhatsappCatalog />',
  });

  const i18n = createI18n({
    legacy: false,
    locale: 'en',
    messages: { en: { CONVERSATION: en.CONVERSATION } },
  });

  const store = createStore({
    getters: { 'accounts/isRTL': () => false },
  });

  return mount(TestHost, {
    attachTo: document.body,
    global: {
      plugins: [i18n, store],
      stubs: { BaseBubble: { template: '<div><slot /></div>' } },
    },
  });
};

const dialogs = () => document.body.querySelectorAll('dialog');
const q = id => document.body.querySelector(`[data-test-id="${id}"]`);

describe('WhatsappCatalog', () => {
  beforeEach(() => {
    HTMLDialogElement.prototype.showModal = vi.fn();
    HTMLDialogElement.prototype.close = vi.fn();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('renders a carousel with header, body, footer and opens the detail', async () => {
    const wrapper = mountCatalog('carousel');
    expect(wrapper.text()).toContain('Head');
    expect(wrapper.text()).toContain('Body text');
    expect(wrapper.text()).toContain('Foot');
    expect(wrapper.findAll('[data-test-id="catalog-card"]')).toHaveLength(3);

    await wrapper.find('[data-test-id="catalog-card-view"]').trigger('click');
    expect(dialogs()).toHaveLength(1);
    expect(q('catalog-gallery')).not.toBeNull();
    expect(dialogs()[0].textContent).toContain('Ceramic mug');
    expect(dialogs()[0].textContent).toContain('Details');
    expect(q('catalog-back')).toBeNull();
    wrapper.unmount();
  });

  it('renders a single product card', () => {
    const wrapper = mountCatalog('product', [items[0]]);
    expect(wrapper.findAll('[data-test-id="catalog-card"]')).toHaveLength(1);
    expect(wrapper.text()).toContain('View');
    wrapper.unmount();
  });

  it('renders a product list and navigates list -> detail -> list in one dialog', async () => {
    const wrapper = mountCatalog('product_list');
    expect(wrapper.text()).toContain('Head');
    expect(wrapper.text()).toContain('Body text');
    expect(wrapper.text()).toContain('Kitchen');
    expect(wrapper.text()).toContain('3 items');
    expect(wrapper.text()).toContain('View items');
    expect(wrapper.text().indexOf('Head')).toBeLessThan(
      wrapper.text().indexOf('Body text')
    );

    await wrapper.find('[data-test-id="catalog-view-items"]').trigger('click');
    expect(dialogs()).toHaveLength(1);
    const rows = document.body.querySelectorAll(
      '[data-test-id="catalog-list-row"]'
    );
    expect(rows).toHaveLength(3);

    rows[1].click();
    await wrapper.vm.$nextTick();
    expect(dialogs()).toHaveLength(1);
    expect(dialogs()[0].textContent).toContain('Plate');
    expect(q('catalog-list-row')).toBeNull();

    q('catalog-back').click();
    await wrapper.vm.$nextTick();
    expect(
      document.body.querySelectorAll('[data-test-id="catalog-list-row"]')
    ).toHaveLength(3);
    expect(q('catalog-back')).toBeNull();
    expect(dialogs()).toHaveLength(1);
    wrapper.unmount();
  });

  it('groups the dialog list by section when there are several', async () => {
    const twoSections = [
      { ...items[0], section: 'Kitchen' },
      { ...items[1], section: 'Living room' },
      { ...items[2], section: 'Kitchen' },
    ];
    const wrapper = mountCatalog('product_list', twoSections);
    await wrapper.find('[data-test-id="catalog-view-items"]').trigger('click');

    const titles = [
      ...document.body.querySelectorAll(
        '[data-test-id="catalog-section-title"]'
      ),
    ].map(el => el.textContent.trim());
    expect(titles).toEqual(['Kitchen', 'Living room']);

    const sections = document.body.querySelectorAll(
      '[data-test-id="catalog-list-section"]'
    );
    const names = [...sections].map(section =>
      [...section.querySelectorAll('[data-test-id="catalog-list-row"]')].map(
        row => row.textContent.trim()
      )
    );
    expect(names[0].join(' ')).toContain('Mug');
    expect(names[0].join(' ')).toContain('Bowl');
    expect(names[1].join(' ')).toContain('Plate');
    expect(dialogs()[0].textContent).toContain('Head');
    wrapper.unmount();
  });

  it('shows no section titles when all items share one section', async () => {
    const wrapper = mountCatalog('product_list');
    await wrapper.find('[data-test-id="catalog-view-items"]').trigger('click');
    expect(q('catalog-section-title')).toBeNull();
    wrapper.unmount();
  });
});
