import NotificationBell from '../NotificationBell';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import VueI18n from 'vue-i18n';

import i18n from 'dashboard/i18n';

const localVue = createLocalVue();
localVue.use(Vuex);
localVue.use(VueI18n);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

describe('notificationBell', () => {
  const accountId = 1;
  const notificationMetadata = { unreadCount: 19 };
  let store = null;
  let actions = null;
  let modules = null;

  beforeEach(() => {
    actions = {
      showNotification: jest.fn(),
    };
    modules = {
      auth: {
        getters: {
          getCurrentAccountId: () => accountId,
        },
      },
      notifications: {
        getters: {
          'notifications/getMeta': () => notificationMetadata,
        },
      },
    };

    store = new Vuex.Store({
      actions,
      modules,
    });
  });

  it('it should return unread count 19 ', () => {
    const notificationBell = shallowMount(NotificationBell, {
      store,
      localVue,
      i18n: i18nConfig,
    });
    const statusViewTitle = notificationBell.find('.unread-badge');
    expect(statusViewTitle.text()).toBe('19');
  });

  it('it should return unread count 99+ ', async () => {
    notificationMetadata.unreadCount = 101;
    const notificationBell = shallowMount(NotificationBell, {
      store,
      localVue,
      i18n: i18nConfig,
    });
    const statusViewTitle = notificationBell.find('.unread-badge');
    expect(statusViewTitle.text()).toBe('99+');
  });
});
