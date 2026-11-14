import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import ViewWithHeader from '../ViewWithHeader.vue';

const mountView = ({ appConfig = {}, channel = {}, routeName = 'home' }) => {
  window.chatwootWebChannel = {
    avatarUrl: '',
    enabledFeatures: [],
    websiteName: 'Acme',
    welcomeTitle: '',
    welcomeTagline: '',
    ...channel,
  };
  const store = createStore({
    modules: {
      appConfig: {
        namespaced: true,
        getters: {
          getAppConfig: () => ({
            welcomeTitle: '',
            welcomeDescription: '',
            ...appConfig,
          }),
        },
      },
      agent: {
        namespaced: true,
        getters: { availableAgents: () => [] },
      },
    },
  });
  return shallowMount(ViewWithHeader, {
    global: {
      plugins: [store],
      mocks: { $route: { name: routeName } },
      stubs: { RouterView: true },
    },
  });
};

const expandedHeader = wrapper =>
  wrapper.findComponent({ name: 'ChatHeaderExpanded' });

describe('ViewWithHeader', () => {
  afterEach(() => {
    delete window.chatwootWebChannel;
  });

  it('expands the header with the SDK welcome texts when the inbox has none', () => {
    const wrapper = mountView({
      appConfig: { welcomeTitle: 'Hi there', welcomeDescription: 'Ask away' },
    });

    expect(expandedHeader(wrapper).exists()).toBe(true);
    expect(expandedHeader(wrapper).props('introHeading')).toBe('Hi there');
    expect(expandedHeader(wrapper).props('introBody')).toBe('Ask away');
  });

  it('expands the header with only the SDK title', () => {
    const wrapper = mountView({ appConfig: { welcomeTitle: 'Hi there' } });

    expect(expandedHeader(wrapper).props('introHeading')).toBe('Hi there');
  });

  it('expands the header with only the SDK description', () => {
    const wrapper = mountView({
      appConfig: { welcomeDescription: 'Ask away' },
    });

    expect(expandedHeader(wrapper).props('introBody')).toBe('Ask away');
  });

  it('prefers the SDK description over the inbox tagline', () => {
    const wrapper = mountView({
      appConfig: { welcomeDescription: 'Page body' },
      channel: { welcomeTagline: 'Inbox tag' },
    });

    expect(expandedHeader(wrapper).props('introBody')).toBe('Page body');
  });

  it('prefers the SDK texts over the inbox ones', () => {
    const wrapper = mountView({
      appConfig: { welcomeTitle: 'From the page' },
      channel: { welcomeTitle: 'From the inbox', welcomeTagline: 'Inbox tag' },
    });

    expect(expandedHeader(wrapper).props('introHeading')).toBe('From the page');
    expect(expandedHeader(wrapper).props('introBody')).toBe('Inbox tag');
  });

  it('keeps the header collapsed when neither the SDK nor the inbox has a text', () => {
    const wrapper = mountView({});

    expect(expandedHeader(wrapper).exists()).toBe(false);
  });
});
