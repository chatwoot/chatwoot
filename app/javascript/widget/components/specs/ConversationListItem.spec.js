import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import ConversationListItem from '../ConversationListItem.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const store = createStore({
  modules: {
    appConfig: {
      namespaced: true,
      getters: { getWidgetColor: () => '#1f93ff' },
    },
  },
});

const conversation = {
  id: 7,
  status: 'open',
  unread_count: 0,
  last_activity_at: Math.floor(Date.now() / 1000),
  last_message: {
    content: 'Sure, sending it now',
    message_type: 1,
    sender: { available_name: 'Jane Agent', avatar_url: '/jane.png' },
  },
};

const mountItem = props =>
  mount(ConversationListItem, {
    props: { conversation, ...props },
    global: { plugins: [store], stubs: { Avatar: true } },
  });

describe('ConversationListItem', () => {
  beforeEach(() => {
    window.chatwootWebChannel = {
      websiteName: 'Acme',
      avatarUrl: '/inbox.png',
      enabledFeatures: [],
    };
  });

  afterEach(() => {
    delete window.chatwootWebChannel;
  });

  it('titles the row with the conversation number and shows the last agent as the sender', () => {
    const wrapper = mountItem();
    expect(wrapper.text()).toContain('#7');
    expect(wrapper.text()).toContain('Sure, sending it now');
    expect(wrapper.findComponent(Avatar).props()).toMatchObject({
      src: '/jane.png',
      name: 'Jane Agent',
    });
    expect(wrapper.find('.sr-only').exists()).toBe(false);
  });

  it('uses the bot identity for template messages', () => {
    const wrapper = mountItem({
      conversation: {
        ...conversation,
        last_message: { content: 'Rate your conversation', message_type: 3 },
      },
    });
    expect(wrapper.findComponent(Avatar).props()).toMatchObject({
      src: '/assets/images/chatwoot_bot.png',
      name: 'UNREAD_VIEW.BOT',
    });
  });

  it('uses the inbox identity for bots when the inbox avatar is enabled for them', () => {
    window.chatwootWebChannel.enabledFeatures = ['use_inbox_avatar_for_bot'];
    const wrapper = mountItem({
      conversation: {
        ...conversation,
        last_message: { content: 'Hi there', message_type: 1 },
      },
    });
    expect(wrapper.findComponent(Avatar).props()).toMatchObject({
      src: '/inbox.png',
      name: 'Acme',
    });
  });

  it('shows no sender avatar and prefixes the preview for visitor messages', () => {
    const wrapper = mountItem({
      conversation: {
        ...conversation,
        last_message: {
          content: 'Is it [shipped](https://a.b)?',
          message_type: 0,
        },
      },
    });
    expect(wrapper.findComponent(Avatar).exists()).toBe(false);
    expect(wrapper.text()).toContain('YOU: Is it shipped?');
  });

  it('announces unread messages to assistive technology', () => {
    const wrapper = mountItem({
      conversation: { ...conversation, unread_count: 3 },
    });
    expect(wrapper.find('.sr-only').text()).toBe('CONVERSATIONS.UNREAD_COUNT');
    expect(wrapper.text()).toContain('3');
  });

  it('labels resolved conversations', () => {
    const wrapper = mountItem({
      conversation: { ...conversation, status: 'resolved' },
    });
    expect(wrapper.text()).toContain('CONVERSATIONS.RESOLVED');
  });

  it('is a button that selects the conversation', async () => {
    const wrapper = mountItem();
    expect(wrapper.element.tagName).toBe('BUTTON');
    await wrapper.trigger('click');
    expect(wrapper.emitted('select')).toEqual([[7]]);
  });
});
