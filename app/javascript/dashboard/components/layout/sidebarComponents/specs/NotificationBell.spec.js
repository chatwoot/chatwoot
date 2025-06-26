import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';
import NotificationBell from '../NotificationBell.vue';

const $route = {
  name: 'notifications_index',
};

describe('notificationBell', () => {
  const accountId = 1;
  const notificationMetadata = { unreadCount: 19 };
  let store = null;
  let actions = null;
  let modules = null;

  beforeEach(() => {
    actions = {
      showNotification: vi.fn(),
    };
    modules = {
      auth: {
        namespaced: false,
        getters: {
          getCurrentAccountId: () => accountId,
        },
      },
      notifications: {
        namespaced: false,
        getters: {
          'notifications/getMeta': () => notificationMetadata,
        },
      },
    };

    store = createStore({
      actions,
      modules,
    });
  });

  it('it should return unread count 19', () => {
    const wrapper = shallowMount(NotificationBell, {
      global: {
        plugins: [store],
        mocks: {
          $route,
        },
        components: {
          'fluent-icon': FluentIcon,
        },
      },
    });
    expect(wrapper.vm.unreadCount).toBe('19');
  });

  it('it should return unread count 99+', async () => {
    notificationMetadata.unreadCount = 100;
    const wrapper = shallowMount(NotificationBell, {
      global: {
        plugins: [store],
        mocks: {
          $route,
        },
        components: {
          'fluent-icon': FluentIcon,
        },
      },
    });
    expect(wrapper.vm.unreadCount).toBe('99+');
  });

  it('isNotificationPanelActive', async () => {
    const notificationBell = shallowMount(NotificationBell, {
      global: {
        plugins: [store],
        mocks: {
          $route,
        },
        components: {
          'fluent-icon': FluentIcon,
        },
      },
    });

    expect(notificationBell.vm.isNotificationPanelActive).toBe(true);
  });
});
