import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import ReportsFiltersInboxes from '../../Filters/Inboxes.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const mountParams = {
  mocks: {
    $t: msg => msg,
  },
  stubs: ['multiselect'],
};

describe('ReportsFiltersInboxes.vue', () => {
  let store;
  let inboxesModule;

  beforeEach(() => {
    inboxesModule = {
      namespaced: true,
      getters: {
        getInboxes: () => () => [
          { id: 1, name: 'Inbox 1' },
          { id: 2, name: 'Inbox 2' },
        ],
      },
      actions: {
        get: vi.fn(),
      },
    };

    store = new Vuex.Store({
      modules: {
        inboxes: inboxesModule,
      },
    });
  });

  it('dispatches "inboxes/get" action when component is mounted', () => {
    shallowMount(ReportsFiltersInboxes, {
      store,
      localVue,
      ...mountParams,
    });
    expect(inboxesModule.actions.get).toHaveBeenCalled();
  });

  it('emits "inbox-filter-selection" event when handleInput is called', () => {
    const wrapper = shallowMount(ReportsFiltersInboxes, {
      store,
      localVue,
      ...mountParams,
    });

    const selectedInbox = { id: 1, name: 'Inbox 1' };
    wrapper.setData({ selectedOption: selectedInbox });

    wrapper.vm.handleInput();

    expect(wrapper.emitted('inbox-filter-selection')).toBeTruthy();
    expect(wrapper.emitted('inbox-filter-selection')[0]).toEqual([
      selectedInbox,
    ]);
  });
});
