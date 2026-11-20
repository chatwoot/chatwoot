import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import NetworkNotification from '../NetworkNotification.vue';

const { eventHandlers } = vi.hoisted(() => ({
  eventHandlers: new Map(),
}));

vi.mock('dashboard/composables/emitter', () => ({
  useEmitter: (eventName, callback) => {
    eventHandlers.set(eventName, callback);
  },
}));

vi.mock('@vueuse/core', () => ({
  useEventListener: vi.fn(),
}));

vi.mock('vue-router', () => ({
  useRoute: () => ({ name: 'conversation_list' }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/helper/routeHelpers', () => ({
  isAConversationRoute: () => true,
  isAInboxViewRoute: () => false,
}));

describe('NetworkNotification', () => {
  let wrapper;

  beforeEach(() => {
    vi.useFakeTimers();
    eventHandlers.clear();
    vi.spyOn(window.navigator, 'onLine', 'get').mockReturnValue(true);
    wrapper = mount(NetworkNotification, {
      global: {
        mocks: { $t: key => key },
        stubs: {
          Button: true,
          'fluent-icon': true,
        },
      },
    });
  });

  afterEach(() => {
    wrapper.unmount();
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('keeps the banner visible when the socket disconnects during the reconnected timeout', async () => {
    eventHandlers.get(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED)();
    await nextTick();

    expect(wrapper.text()).toContain('NETWORK.NOTIFICATION.RECONNECT_SUCCESS');

    vi.advanceTimersByTime(1000);
    eventHandlers.get(BUS_EVENTS.WEBSOCKET_DISCONNECT)();
    await nextTick();
    vi.advanceTimersByTime(2000);
    await nextTick();

    const banner = wrapper.find('.fixed');
    expect(banner.attributes('style')).not.toContain('display: none');
    expect(wrapper.text()).toContain('NETWORK.NOTIFICATION.OFFLINE');
  });
});
