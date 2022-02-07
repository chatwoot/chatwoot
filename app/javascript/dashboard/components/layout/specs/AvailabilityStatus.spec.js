import AvailabilityStatus from '../AvailabilityStatus.vue';
import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import VueI18n from 'vue-i18n';

import WootButton from 'dashboard/components/ui/WootButton';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu';
import WootDropdownHeader from 'shared/components/ui/dropdown/DropdownHeader';
import WootDropdownDivider from 'shared/components/ui/dropdown/DropdownDivider';
import i18n from 'dashboard/i18n';

const localVue = createLocalVue();
localVue.use(Vuex);
localVue.use(VueI18n);
localVue.component('woot-button', WootButton);
localVue.component('woot-dropdown-header', WootDropdownHeader);
localVue.component('woot-dropdown-menu', WootDropdownMenu);
localVue.component('woot-dropdown-divider', WootDropdownDivider);
localVue.component('woot-dropdown-item', WootDropdownItem);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

describe('AvailabilityStatus', () => {
  const currentAvailability = 'online';
  const currentAccountId = '1';
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
          getCurrentUserAvailability: () => currentAvailability,
          getCurrentAccountId: () => currentAccountId,
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
      i18n: i18nConfig,
    });
  });

  it('dispatches an action when user changes status', async () => {
    await availabilityStatus;
    availabilityStatus
      .findAll('.status-change--dropdown-button')
      .at(2)
      .trigger('click');

    expect(actions.updateAvailability).toBeCalledWith(
      expect.any(Object),
      { availability: 'offline', account_id: currentAccountId },
      undefined
    );
  });
});
