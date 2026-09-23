import { mount } from '@vue/test-utils';
import ContactConversationLink from '../ContactConversationLink.vue';

const conversation = (message = {}) => ({
  id: 11,
  created_at: 1700000000,
  meta: { sender: { name: 'Jane Doe' } },
  messages: [
    {
      id: 1,
      content: 'Hello there',
      message_type: 0,
      attachments: [],
      ...message,
    },
  ],
});

const mountComponent = (props = {}) =>
  mount(ContactConversationLink, {
    props: {
      conversation: conversation(),
      to: '/conversations/11',
      direction: 'older',
      ...props,
    },
    global: {
      stubs: {
        Icon: true,
        'fluent-icon': true,
        RouterLink: { props: ['to'], template: '<slot :href="to" />' },
      },
    },
  });

describe('ContactConversationLink', () => {
  it('renders the direction label, preview and start date', () => {
    const wrapper = mountComponent();

    expect(wrapper.text()).toContain('CONVERSATION.CONTACT_HISTORY.OLDER');
    expect(wrapper.text()).toContain('Hello there');
    expect(wrapper.text()).toContain('Nov 14, 2023');
    expect(wrapper.find('a').attributes('href')).toBe('/conversations/11');
  });

  it('labels the newer direction', () => {
    const wrapper = mountComponent({ direction: 'newer' });

    expect(wrapper.text()).toContain('CONVERSATION.CONTACT_HISTORY.NEWER');
  });

  it('previews only the first paragraph of an email', () => {
    const wrapper = mountComponent({
      conversation: conversation({
        content:
          'heyeyeyey\n\n---------- Forwarded message ---------\nFrom: Jane',
      }),
    });

    expect(wrapper.text()).toContain('heyeyeyey');
    expect(wrapper.text()).not.toContain('Forwarded');
  });

  it('describes an attachment when the message has no text', () => {
    const wrapper = mountComponent({
      conversation: conversation({
        content: '',
        attachments: [{ file_type: 'image' }],
      }),
    });

    expect(wrapper.text()).toContain('CHAT_LIST.ATTACHMENTS.image.CONTENT');
  });

  it('skips the preview when there is no message', () => {
    const wrapper = mountComponent({
      conversation: { ...conversation(), messages: [] },
    });

    expect(wrapper.text()).not.toContain('Hello there');
    expect(wrapper.findComponent({ name: 'MessagePreview' }).exists()).toBe(
      false
    );
  });

  it('hands a plain click to the parent and leaves modified clicks to the browser', async () => {
    const wrapper = mountComponent();

    await wrapper.find('a').trigger('click');
    expect(wrapper.emitted('navigate')).toHaveLength(1);

    await wrapper.find('a').trigger('click', { metaKey: true });
    expect(wrapper.emitted('navigate')).toHaveLength(1);
  });
});
