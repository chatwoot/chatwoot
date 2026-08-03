import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import CardButton from '../CardButton.vue';

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
});
