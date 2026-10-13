import { mount } from '@vue/test-utils';
import WhatsAppInteractivePreview from '../WhatsAppInteractivePreview.vue';

describe('WhatsAppInteractivePreview', () => {
  const global = { mocks: { $t: key => key } };

  it('preserves a native list opener, sections, row titles, and descriptions', () => {
    const wrapper = mount(WhatsAppInteractivePreview, {
      global,
      props: {
        type: 'list',
        header: { type: 'text', text: 'Choose a group' },
        body: 'Pick one option',
        footer: 'One selection only',
        opener: 'View options',
        sections: [
          {
            title: 'Support',
            rows: [
              { title: 'Billing', description: 'Questions about invoices' },
            ],
          },
        ],
      },
    });

    expect(wrapper.text()).toContain('Choose a group');
    expect(wrapper.text()).toContain('Pick one option');
    expect(wrapper.text()).toContain('One selection only');
    expect(wrapper.text()).toContain('View options');
    expect(wrapper.text()).toContain('Support');
    expect(wrapper.text()).toContain('Billing');
    expect(wrapper.text()).toContain('Questions about invoices');
  });

  it('retains the disabled reply-button preview', () => {
    const wrapper = mount(WhatsAppInteractivePreview, {
      global,
      props: {
        type: 'button',
        body: 'Choose',
        buttons: [{ title: 'Confirm' }],
      },
    });

    expect(wrapper.get('button').attributes('disabled')).toBe('');
    expect(wrapper.get('button').text()).toBe('Confirm');
  });

  it('shows a disabled CTA action and readable destination', () => {
    const wrapper = mount(WhatsAppInteractivePreview, {
      global,
      props: {
        type: 'cta_url',
        header: { type: 'text', text: 'Order update' },
        body: 'Your order is ready',
        footer: 'Secure link',
        opener: 'View details',
        url: 'https://example.test/details',
      },
    });

    expect(wrapper.get('button').attributes('disabled')).toBe('');
    expect(wrapper.get('button').text()).toBe('View details');
    expect(wrapper.get('[data-testid="whatsapp-cta-destination"]').text()).toBe(
      'https://example.test/details'
    );
    expect(wrapper.text()).toContain('Order update');
    expect(wrapper.text()).toContain('Your order is ready');
    expect(wrapper.text()).toContain('Secure link');
  });
});
