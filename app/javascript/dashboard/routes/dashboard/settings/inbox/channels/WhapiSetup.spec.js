import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { mount } from '@vue/test-utils';
import Whapi from './Whapi.vue';

vi.mock('dashboard/composables', () => ({
  useAlert: msg => ({ show: vi.fn(), ...(msg ? { message: msg } : {}) }),
}));

vi.mock('vuex', async () => {
  const actual = await vi.importActual('vuex');
  return {
    ...actual,
    mapGetters: () => ({}),
  };
});

describe('Whapi.vue', () => {
  let store;
  let actions;

  beforeEach(() => {
    actions = {
      'inboxes/createWhapiChannel': vi.fn().mockResolvedValue({
        id: 12,
        name: 'My Inbox',
        provider_config: { connection_status: 'pending' },
      }),
      'inboxes/getWhapiQrCode': vi.fn().mockResolvedValue({
        image_base64: 'B64',
        poll_in: 15,
        expires_in: 20,
      }),
    };

    store = {
      dispatch: (type, payload) => actions[type](payload),
      getters: {
        'inboxes/getUIFlags': { isCreating: false },
        'inboxes/getInbox': () => () => ({
          id: 12,
          provider_config: { connection_status: 'pending' },
        }),
      },
    };
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('creates channel then moves to qr step and fetches QR', async () => {
    const wrapper = mount(Whapi, {
      global: {
        mocks: { 
          $store: store, 
          $t: k => k 
        },
        stubs: ['NextButton'],
      },
      computed: {
        uiFlags: () => ({ isCreating: false }),
      },
    });

    await wrapper.setData({ inboxName: 'My Inbox' });
    await wrapper.find('form').trigger('submit.prevent');

    expect(actions['inboxes/createWhapiChannel']).toHaveBeenCalled();
    expect(actions['inboxes/getWhapiQrCode']).toHaveBeenCalled();
    expect(wrapper.vm.step).toBe('qr');
    expect(wrapper.vm.qrImageB64).toContain('data:image/png;base64,');
  });

  it('transitions to success when connection status becomes connected', async () => {
    const wrapper = mount(Whapi, {
      global: {
        mocks: {
          $store: {
            ...store,
            getters: {
              ...store.getters,
              'inboxes/getInbox': () => () => ({
                id: 12,
                provider_config: { connection_status: 'connected' },
              }),
            },
          },
          $t: k => k,
        },
        stubs: ['NextButton'],
      },
      computed: {
        uiFlags: () => ({ isCreating: false }),
      },
    });

    await wrapper.setData({ step: 'qr' });
    await wrapper.vm.$nextTick();

    // Trigger watcher by forcing computed reevaluation
    wrapper.vm.$options.watch.connectionStatus.call(wrapper.vm, 'connected');
    expect(wrapper.vm.step).toBe('success');
  });
});
