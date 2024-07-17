import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import ReportsFiltersAgents from '../../Filters/Agents.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const mockStore = new Vuex.Store({
  modules: {
    agents: {
      namespaced: true,
      state: {
        agents: [],
      },
      getters: {
        getAgents: state => state.agents,
      },
      actions: {
        get: vi.fn(),
      },
    },
  },
});

const mountParams = {
  localVue,
  store: mockStore,
  mocks: {
    $t: msg => msg,
  },
  stubs: ['multiselect'],
};

describe('ReportsFiltersAgents.vue', () => {
  it('emits "agents-filter-selection" event when handleInput is called', () => {
    const wrapper = shallowMount(ReportsFiltersAgents, mountParams);

    const selectedAgents = [
      { id: 1, name: 'Agent 1' },
      { id: 2, name: 'Agent 2' },
    ];
    wrapper.setData({ selectedOptions: selectedAgents });

    wrapper.vm.handleInput();

    expect(wrapper.emitted('agents-filter-selection')).toBeTruthy();
    expect(wrapper.emitted('agents-filter-selection')[0]).toEqual([
      selectedAgents,
    ]);
  });

  it('dispatches the "agents/get" action when the component is mounted', () => {
    const dispatchSpy = vi.spyOn(mockStore, 'dispatch');

    shallowMount(ReportsFiltersAgents, mountParams);

    expect(dispatchSpy).toHaveBeenCalledWith('agents/get');
  });
});
