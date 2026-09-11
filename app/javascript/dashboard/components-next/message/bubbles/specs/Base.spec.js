import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import MessageBubbleBase from '../Base.vue';
import { provideMessageContext } from '../../provider.js';

const mountBase = inReplyTo => {
  const TestHost = defineComponent({
    components: { MessageBubbleBase },
    setup() {
      provideMessageContext({
        id: ref(1),
        content: ref('Resposta'),
        createdAt: ref(1_723_456_789),
        inReplyTo: ref(inReplyTo),
        variant: ref('outgoing'),
        orientation: ref('right'),
        shouldGroupWithNext: ref(false),
        sender: ref({ type: 'user' }),
        senderType: ref('user'),
        status: ref('sent'),
      });
    },
    template: '<MessageBubbleBase />',
  });

  return mount(TestHost, {
    global: {
      mocks: { $t: key => key },
      directives: { 'dompurify-html': {} },
      stubs: { MessageMeta: true, CaptainGenerationDetails: true },
    },
  });
};

const imageAttachment = {
  file_type: 'image',
  thumb_url: 'https://cdn.example.com/thumb.jpg',
  data_url: 'https://cdn.example.com/full.jpg',
};

describe('Base bubble reply preview', () => {
  // The word "Image" says nothing about which photo is being answered; the picture does.
  it('shows the thumbnail of a quoted image', () => {
    const wrapper = mountBase({
      id: 7,
      content: '',
      attachments: [imageAttachment],
    });
    const img = wrapper.find('img');

    expect(img.exists()).toBe(true);
    expect(img.attributes('src')).toBe('https://cdn.example.com/thumb.jpg');
  });

  // A caption used to win over the attachment, so a photo sent with text lost its preview.
  it('still shows the thumbnail when the quoted image has a caption', () => {
    const wrapper = mountBase({
      id: 7,
      content: 'Quero essa',
      attachments: [imageAttachment],
    });

    expect(wrapper.find('img').attributes('src')).toBe(
      'https://cdn.example.com/thumb.jpg'
    );
  });

  it('shows no thumbnail for a quoted file that is not an image', () => {
    const wrapper = mountBase({
      id: 7,
      content: '',
      attachments: [
        { file_type: 'file', data_url: 'https://cdn.example.com/a.pdf' },
      ],
    });

    expect(wrapper.find('img').exists()).toBe(false);
  });

  it('renders no reply block when the message answers nothing', () => {
    const wrapper = mountBase(null);

    expect(wrapper.find('img').exists()).toBe(false);
    expect(wrapper.text()).not.toContain('CHAT_LIST.ATTACHMENTS');
  });

  // The alt used to receive the formatted caption, so a screen reader announced raw HTML.
  it('describes the thumbnail with plain text', () => {
    const wrapper = mountBase({
      id: 7,
      content: 'Quero essa',
      attachments: [imageAttachment],
    });

    expect(wrapper.find('img').attributes('alt')).toBe(
      'CHAT_LIST.ATTACHMENTS.image.CONTENT'
    );
  });
});
