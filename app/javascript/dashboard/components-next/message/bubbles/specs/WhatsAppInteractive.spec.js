import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import WhatsAppInteractive from '../WhatsAppInteractive.vue';
import { provideMessageContext } from '../../provider.js';

const mountBubble = ({
  interactive = {
    schemaVersion: 1,
    type: 'button',
    body: { text: 'Please choose one option.' },
    footer: { text: 'Footer' },
    action: {
      buttons: [
        { deliveryId: 'reply-1', title: 'Confirm' },
        { deliveryId: 'reply-2', title: 'Change' },
      ],
    },
  },
  content = 'Please choose one option.',
  attachments = [],
} = {}) => {
  const TestHost = defineComponent({
    components: { WhatsAppInteractive },
    setup() {
      provideMessageContext({
        content: ref(content),
        attachments: ref(attachments),
        contentAttributes: ref({
          whatsappInteractive: interactive,
        }),
      });
    },
    template: '<WhatsAppInteractive />',
  });

  return mount(TestHost, {
    global: {
      mocks: { $t: key => key },
      stubs: { BaseBubble: { template: '<div><slot /></div>' } },
    },
  });
};

describe('WhatsAppInteractive', () => {
  it('renders the persisted body and reply labels as disabled controls', () => {
    const wrapper = mountBubble();
    const buttons = wrapper.findAll('button');

    expect(wrapper.text()).toContain('Please choose one option.');
    expect(wrapper.text()).toContain('Footer');
    expect(buttons.map(button => button.text())).toEqual(['Confirm', 'Change']);
    expect(
      buttons.every(button => button.attributes('disabled') !== undefined)
    ).toBe(true);
  });

  it('renders the persisted text header', () => {
    const wrapper = mountBubble({
      interactive: {
        type: 'button',
        header: { type: 'text', text: 'Header' },
        body: { text: 'Body' },
        action: { buttons: [] },
      },
    });
    expect(wrapper.text()).toContain('Header');
  });

  it.each(['image', 'video', 'document'])(
    'renders the %s header using the snapshot attachment ID',
    type => {
      const wrapper = mountBubble({
        interactive: {
          type: 'button',
          header: { type, attachmentId: 22 },
          body: { text: 'Body' },
          action: { buttons: [] },
        },
        attachments: [
          { id: 11, dataUrl: 'https://example.com/wrong.png' },
          { id: 22, dataUrl: 'https://example.com/header.pdf' },
        ],
      });
      const media = wrapper.find(
        { image: 'img', video: 'video', document: 'a' }[type]
      );
      expect(media.attributes(type === 'document' ? 'href' : 'src')).toBe(
        'https://example.com/header.pdf'
      );
      if (type === 'document') expect(media.text()).toBe('header.pdf');
    }
  );

  it('does not display an unrelated attachment as the header', () => {
    const wrapper = mountBubble({
      interactive: {
        type: 'button',
        header: { type: 'image', attachmentId: 22 },
        body: { text: 'Body' },
        action: { buttons: [] },
      },
      attachments: [{ id: 11, dataUrl: 'https://example.com/wrong.png' }],
    });
    expect(wrapper.find('img').exists()).toBe(false);
  });

  it('renders a stored list with its opener, sections, rows, and descriptions', () => {
    const wrapper = mountBubble({
      interactive: {
        type: 'list',
        header: { type: 'text', text: 'Available meals' },
        body: { text: 'Choose a meal.' },
        footer: { text: 'One selection per order.' },
        action: {
          button: 'View meals',
          sections: [
            {
              title: 'Lunch',
              rows: [
                { title: 'Pasta', description: 'Tomato and basil' },
                { title: 'Salad' },
              ],
            },
          ],
        },
      },
    });

    expect(wrapper.text()).toContain('Available meals');
    expect(wrapper.text()).toContain('Choose a meal.');
    expect(wrapper.text()).toContain('One selection per order.');
    expect(wrapper.text()).toContain('View meals');
    expect(wrapper.text()).toContain('Lunch');
    expect(wrapper.text()).toContain('Pasta');
    expect(wrapper.text()).toContain('Tomato and basil');
    expect(wrapper.text()).toContain('Salad');
    expect(wrapper.find('button').attributes('disabled')).not.toBeUndefined();
  });

  it('renders a stored CTA URL as a disabled action with its destination', () => {
    const wrapper = mountBubble({
      interactive: {
        type: 'cta_url',
        header: { type: 'text', text: 'Order update' },
        body: { text: 'Your order is ready to review.' },
        footer: { text: 'Secure link' },
        action: {
          button: 'View details',
          url: 'https://example.test/details',
        },
      },
    });

    expect(wrapper.text()).toContain('Order update');
    expect(wrapper.text()).toContain('Your order is ready to review.');
    expect(wrapper.text()).toContain('Secure link');
    expect(wrapper.find('button').text()).toBe('View details');
    expect(wrapper.find('button').attributes('disabled')).not.toBeUndefined();
    expect(wrapper.get('[data-testid="whatsapp-cta-destination"]').text()).toBe(
      'https://example.test/details'
    );
  });

  it('renders each stored URL carousel card with only its referenced image', () => {
    const wrapper = mountBubble({
      interactive: {
        type: 'carousel',
        body: { text: 'Choose a destination.' },
        action: {
          cards: [
            {
              cardIndex: 0,
              type: 'cta_url',
              header: { type: 'image', attachmentId: 101 },
              body: { text: 'Mountain escape' },
              action: {
                button: 'View mountain',
                url: 'https://example.test/mountain',
              },
            },
            {
              cardIndex: 1,
              type: 'cta_url',
              header: { type: 'image', attachmentId: 102 },
              action: {
                button: 'View beach',
                url: 'https://example.test/beach',
              },
            },
          ],
        },
      },
      attachments: [
        { id: 999, dataUrl: 'https://example.test/unrelated.jpg' },
        { id: '101', dataUrl: 'https://example.test/mountain.jpg' },
      ],
    });

    expect(wrapper.text()).toContain('Choose a destination.');
    expect(wrapper.text()).toContain('Mountain escape');
    expect(wrapper.text()).toContain('View mountain');
    expect(wrapper.text()).toContain('https://example.test/mountain');
    expect(wrapper.text()).toContain('View beach');
    expect(wrapper.findAll('img')).toHaveLength(1);
    expect(wrapper.get('img').attributes('src')).toBe(
      'https://example.test/mountain.jpg'
    );
    expect(wrapper.text()).toContain(
      'CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.IMAGE_REQUIRED'
    );
  });

  it('renders stored carousel quick replies as disabled controls', () => {
    const wrapper = mountBubble({
      interactive: {
        type: 'carousel',
        body: { text: 'Choose a destination.' },
        action: {
          cards: [
            {
              type: 'button',
              header: { type: 'image', attachment_id: 101 },
              action: {
                buttons: [
                  { deliveryId: 'reply-1', title: 'Choose' },
                  { deliveryId: 'reply-2', title: 'Details' },
                ],
              },
            },
          ],
        },
      },
      attachments: [{ id: 101, dataUrl: 'https://example.test/mountain.jpg' }],
    });
    const buttons = wrapper.findAll('button');

    expect(buttons.map(button => button.text())).toEqual(['Choose', 'Details']);
    expect(
      buttons.every(button => button.attributes('disabled') !== undefined)
    ).toBe(true);
    expect(wrapper.get('img').attributes('src')).toBe(
      'https://example.test/mountain.jpg'
    );
  });
});
