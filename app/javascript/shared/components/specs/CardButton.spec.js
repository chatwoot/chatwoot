import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import CardButton from '../CardButton.vue';
import { IFrameHelper } from 'widget/helpers/utils';

vi.mock('widget/helpers/utils', () => ({
  IFrameHelper: {
    isIFrame: vi.fn(() => true),
    sendMessage: vi.fn(),
  },
}));

describe('CardButton.vue', () => {
  const store = createStore({
    getters: {
      'appConfig/getWidgetColor': () => '#1f93ff',
    },
  });

  const mountComponent = action =>
    mount(CardButton, {
      props: { action },
      global: { plugins: [store] },
    });

  it('renders a url action as an anchor', () => {
    const wrapper = mountComponent({
      type: 'url',
      text: 'Visit us',
      uri: 'https://example.com',
    });

    const anchor = wrapper.find('a');
    expect(anchor.exists()).toBe(true);
    expect(anchor.attributes('href')).toBe('https://example.com');
  });

  it('renders a link action as an anchor', () => {
    const wrapper = mountComponent({
      type: 'link',
      text: 'Visit us',
      uri: 'https://example.com',
    });

    expect(wrapper.find('a').exists()).toBe(true);
  });

  it('renders a postback action as a button', () => {
    const wrapper = mountComponent({
      type: 'postback',
      text: 'Choose',
      payload: 'choice_1',
    });

    expect(wrapper.find('a').exists()).toBe(false);
    expect(wrapper.find('button').exists()).toBe(true);
  });

  it('renders a reply action as a button', () => {
    const wrapper = mountComponent({
      type: 'reply',
      text: 'Choose',
      payload: 'choice_1',
    });

    expect(wrapper.find('a').exists()).toBe(false);
    expect(wrapper.find('button').exists()).toBe(true);
  });

  it('dispatches a postback event when a reply action button is clicked', async () => {
    const wrapper = mountComponent({
      type: 'reply',
      text: 'Choose',
      payload: 'choice_1',
    });

    await wrapper.find('button').trigger('click');

    expect(IFrameHelper.sendMessage).toHaveBeenCalledWith({
      event: 'postback',
      data: { payload: 'choice_1' },
    });
  });
});
