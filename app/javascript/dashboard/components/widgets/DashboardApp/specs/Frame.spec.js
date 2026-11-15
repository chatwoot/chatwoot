import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { createStore } from 'vuex';
import Frame from '../Frame.vue';

describe('DashboardAppFrame', () => {
  let store;
  let wrapper;

  beforeEach(() => {
    store = createStore({
      state: {
        contact: {
          id: 2,
          custom_attributes: { customer_plan: 'pro' },
        },
        currentUser: { id: 3, name: 'Agent', email: 'agent@example.com' },
        customAttributes: [],
      },
      getters: {
        getCurrentUser: state => state.currentUser,
        'contacts/getContact': state => () => state.contact,
        'attributes/getAttributes': state => state.customAttributes,
      },
      mutations: {
        setCustomAttributes(state, customAttributes) {
          state.customAttributes = customAttributes;
        },
      },
    });

    wrapper = shallowMount(Frame, {
      attachTo: document.body,
      props: {
        config: [{ type: 'frame', url: 'https://example.com' }],
        currentChat: {
          id: 1,
          meta: { sender: { id: 2 } },
          custom_attributes: { order_type: 'subscription' },
        },
        isVisible: false,
        position: 0,
      },
      global: { plugins: [store] },
    });
  });

  afterEach(() => {
    wrapper.unmount();
    document.body.classList.remove('dark');
  });

  it('sends custom attribute definitions and the resolved theme', async () => {
    const customAttributes = [
      {
        attribute_key: 'customer_plan',
        attribute_display_name: 'Customer plan',
      },
    ];
    store.commit('setCustomAttributes', customAttributes);
    await wrapper.setProps({ isVisible: true });

    const frame = wrapper.find('iframe');
    const postMessage = vi.fn();
    Object.defineProperty(frame.element, 'contentWindow', {
      value: { postMessage },
    });
    await frame.trigger('load');

    const payload = JSON.parse(postMessage.mock.calls[0][0]);
    expect(payload).toMatchObject({
      event: 'appContext',
      data: {
        conversation: {
          custom_attributes: { order_type: 'subscription' },
        },
        contact: {
          custom_attributes: { customer_plan: 'pro' },
        },
        currentAgent: {
          id: 3,
          name: 'Agent',
          email: 'agent@example.com',
        },
        customAttributes,
        theme: 'light',
      },
    });
  });

  it('resends context when custom attribute definitions finish loading', async () => {
    await wrapper.setProps({ isVisible: true });
    const frame = wrapper.find('iframe');
    const postMessage = vi.fn();
    Object.defineProperty(frame.element, 'contentWindow', {
      value: { postMessage },
    });
    await frame.trigger('load');
    postMessage.mockClear();

    store.commit('setCustomAttributes', [{ attribute_key: 'customer_plan' }]);
    await nextTick();

    const payload = JSON.parse(postMessage.mock.calls[0][0]);
    expect(payload.data.customAttributes).toEqual([
      { attribute_key: 'customer_plan' },
    ]);
  });

  it('notifies the embedded app when the resolved theme changes', async () => {
    await wrapper.setProps({ isVisible: true });
    const frame = wrapper.find('iframe');
    const postMessage = vi.fn();
    Object.defineProperty(frame.element, 'contentWindow', {
      value: { postMessage },
    });
    await frame.trigger('load');
    postMessage.mockClear();

    document.body.classList.add('dark');
    await nextTick();

    const payload = JSON.parse(postMessage.mock.calls[0][0]);
    expect(payload.data.theme).toBe('dark');
  });

  it('responds only to the frame requesting refreshed context', async () => {
    wrapper.unmount();
    wrapper = shallowMount(Frame, {
      attachTo: document.body,
      props: {
        config: [
          { type: 'frame', url: 'https://one.example.com' },
          { type: 'frame', url: 'https://two.example.com' },
        ],
        currentChat: { id: 1, meta: { sender: { id: 2 } } },
        isVisible: false,
        position: 0,
      },
      global: { plugins: [store] },
    });
    await wrapper.setProps({ isVisible: true });

    const frames = wrapper.findAll('iframe');
    const firstFrameWindow = { postMessage: vi.fn() };
    const secondFrameWindow = { postMessage: vi.fn() };
    Object.defineProperty(frames[0].element, 'contentWindow', {
      value: firstFrameWindow,
    });
    Object.defineProperty(frames[1].element, 'contentWindow', {
      value: secondFrameWindow,
    });
    await frames[0].trigger('load');
    await frames[1].trigger('load');
    firstFrameWindow.postMessage.mockClear();
    secondFrameWindow.postMessage.mockClear();

    wrapper.vm.triggerEvent({
      data: 'chatwoot-dashboard-app:fetch-info',
      source: secondFrameWindow,
    });

    expect(firstFrameWindow.postMessage).not.toHaveBeenCalled();
    expect(secondFrameWindow.postMessage).toHaveBeenCalledOnce();
  });
});
