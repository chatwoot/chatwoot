import { mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import ProductDetail from '../ProductDetail.vue';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: {
    en: {
      CATALOG: {
        PRODUCT: {
          DESCRIPTION: 'Description',
          PHOTO_OF: '{current} of {total}',
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

const mountDetail = props =>
  mount(ProductDetail, {
    props: { item: props || item },
    global: { plugins: [i18n] },
  });

describe('ProductDetail', () => {
  it('shows the photos, indicator, title, price and description', () => {
    const wrapper = mountDetail();
    const images = wrapper.findAll('[data-test-id="catalog-gallery"] img');
    expect(images.map(img => img.attributes('src'))).toEqual(item.imageUrls);
    expect(
      wrapper.find('[data-test-id="catalog-photo-indicator"]').text()
    ).toBe('1 of 2');
    expect(wrapper.text()).toContain('Mug');
    expect(wrapper.text()).toContain('$ 5.000');
    expect(wrapper.text()).toContain('Ceramic mug');
  });

  it('shows the full url as an external link', () => {
    const link = mountDetail().find('[data-test-id="catalog-detail-link"]');
    expect(link.text()).toBe('https://x/mug');
    expect(link.attributes('target')).toBe('_blank');
  });

  it('has no overlay, dialog or close button of its own', () => {
    const wrapper = mountDetail();
    expect(wrapper.find('[role="dialog"]').exists()).toBe(false);
    expect(wrapper.find('[data-test-id="catalog-detail-close"]').exists()).toBe(
      false
    );
  });

  it('does not render links that are not http or https', () => {
    const unsafeUrl = ['javascript', 'alert(1)'].join(':');
    const wrapper = mountDetail({ ...item, url: unsafeUrl });
    expect(wrapper.find('[data-test-id="catalog-detail-link"]').exists()).toBe(
      false
    );
  });
});
