import { mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import WhatsappCatalogProductDetail from '../WhatsappCatalogProductDetail.vue';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: {
    en: {
      CONVERSATION: {
        WHATSAPP_CATALOG: {
          DESCRIPTION: 'Description',
          PHOTO_OF: 'Photo {current} of {total}',
          PREVIOUS_PHOTO: 'Previous photo',
          NEXT_PHOTO: 'Next photo',
        },
      },
    },
  },
});

const item = {
  name: 'Mug',
  price: '$ 5.000',
  imageUrls: ['https://x/1.jpg', 'https://x/2.jpg'],
  description: 'Ceramic mug',
  url: 'https://x/mug',
};

const mountDetail = () =>
  mount(WhatsappCatalogProductDetail, {
    props: { item },
    global: { plugins: [i18n] },
  });

describe('WhatsappCatalogProductDetail', () => {
  it('shows the photos, indicator, title, price and description', () => {
    const wrapper = mountDetail();
    const images = wrapper.findAll('[data-test-id="catalog-gallery"] img');
    expect(images.map(img => img.attributes('src'))).toEqual(item.imageUrls);
    expect(
      wrapper.find('[data-test-id="catalog-photo-indicator"]').text()
    ).toBe('Photo 1 of 2');
    expect(wrapper.text()).toContain('Mug');
    expect(wrapper.text()).toContain('$ 5.000');
    expect(wrapper.text()).toContain('Ceramic mug');
  });

  it('shows the full url as an external link', () => {
    const link = mountDetail().find('[data-test-id="catalog-detail-link"]');
    expect(link.text()).toBe('https://x/mug');
    expect(link.attributes('target')).toBe('_blank');
    expect(link.attributes('rel')).toBe('noopener noreferrer');
  });

  it('has no overlay or buy buttons of its own', () => {
    const wrapper = mountDetail();
    expect(wrapper.find('[role="dialog"]').exists()).toBe(false);
    expect(wrapper.findAll('button')).toHaveLength(2);
  });
});
