import AvailabilityStatus from '../AvailabilityStatus';
import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import VueI18n from 'vue-i18n';

import i18n from 'dashboard/i18n';

const localVue = createLocalVue();
localVue.use(Vuex);
localVue.use(VueI18n);
localVue.locale('en', i18n.en);

describe('AvailabilityStatus', () => {
  const currentUser = { availability_status: 'online' };
  let store = null;
  let actions = null;
  let modules = null;
  let availabilityStatus = null;

  beforeEach(() => {
    actions = {
      updateAvailability: jest.fn(() => {
        return Promise.resolve();
      }),
    };

    modules = {
      auth: {
        getters: {
          getCurrentUser: () => currentUser,
        },
      },
    };

    store = new Vuex.Store({
      actions,
      modules,
    });

    availabilityStatus = mount(AvailabilityStatus, {
      store,
      localVue,
    });
  });

  it('shows current user status', () => {
    const statusViewTitle = availabilityStatus.find('.status-view--title');

    expect(statusViewTitle.text()).toBe('Online');
  });

  it('opens the menu when user clicks "change"', async () => {
    expect(availabilityStatus.find('.dropdown-pane').exists()).toBe(false);

    await availabilityStatus
      .find('.status-change--change-button')
      .trigger('click');

    expect(availabilityStatus.find('.dropdown-pane').exists()).toBe(true);
  });

  it('dispatches an action when user changes status', async () => {
    await availabilityStatus
      .find('.status-change--change-button')
      .trigger('click');

    await availabilityStatus
      .find('.status-change li:last-child button')
      .trigger('click');

    expect(actions.updateAvailability).toBeCalledWith(
      expect.any(Object),
      { availability: 'offline' },
      undefined
    );
  });
});
