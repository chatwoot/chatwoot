import { mount } from '@vue/test-utils';
import LinkPreviewCard from '../LinkPreviewCard.vue';

describe('LinkPreviewCard', () => {
  it('renders link preview details', () => {
    const wrapper = mount(LinkPreviewCard, {
      props: {
        preview: {
          url: 'https://example.com/post',
          title: 'Example title',
          description: 'Example description',
          imageUrl: 'https://example.com/preview.png',
          faviconUrl: 'https://example.com/favicon.ico',
          siteName: 'Example Site',
        },
      },
    });

    expect(wrapper.get('a').attributes('href')).toBe(
      'https://example.com/post'
    );
    expect(wrapper.get('img').attributes('src')).toBe(
      'https://example.com/preview.png'
    );
    expect(wrapper.text()).toContain('Example Site');
    expect(wrapper.text()).toContain('Example title');
    expect(wrapper.text()).toContain('Example description');
  });

  it('supports snake case attributes from the API payload', () => {
    const wrapper = mount(LinkPreviewCard, {
      props: {
        preview: {
          url: 'https://example.com/post',
          title: 'Example title',
          image_url: 'https://example.com/preview.png',
          favicon_url: 'https://example.com/favicon.ico',
          site_name: 'Example Site',
        },
      },
    });

    expect(wrapper.get('img').attributes('src')).toBe(
      'https://example.com/preview.png'
    );
    expect(wrapper.text()).toContain('Example Site');
  });

  it('falls back to favicon when the preview image fails', async () => {
    const wrapper = mount(LinkPreviewCard, {
      props: {
        preview: {
          url: 'https://example.com/post',
          title: 'Example title',
          imageUrl: 'https://example.com/preview.png',
          faviconUrl: 'https://example.com/favicon.ico',
          siteName: 'Example Site',
        },
      },
    });

    await wrapper.get('img').trigger('error');

    expect(wrapper.get('img').attributes('src')).toBe(
      'https://example.com/favicon.ico'
    );
  });
});
