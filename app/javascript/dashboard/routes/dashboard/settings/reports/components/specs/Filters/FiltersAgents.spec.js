import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import ReportsFiltersAgents from '../../Filters/Agents.vue';

const mockStore = createStore({
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
  global: {
    plugins: [mockStore],
    mocks: {
      $t: msg => msg,
    },
    stubs: ['multiselect'],
  },
};

describe('ReportsFiltersAgents.vue', () => {
  it('emits "agents-filter-selection" event when handleInput is called', async () => {
    const wrapper = shallowMount(ReportsFiltersAgents, mountParams);

    const selectedAgents = [
      { id: 1, name: 'Agent 1' },
      { id: 2, name: 'Agent 2' },
    ];
    await wrapper.setData({ selectedOptions: selectedAgents });

    await wrapper.vm.handleInput();

    expect(wrapper.emitted('agentsFilterSelection')).toBeTruthy();
    expect(wrapper.emitted('agentsFilterSelection')[0]).toEqual([
      selectedAgents,
    ]);
  });

  it('dispatches the "agents/get" action when the component is mounted', () => {
    const dispatchSpy = vi.spyOn(mockStore, 'dispatch');

    shallowMount(ReportsFiltersAgents, mountParams);

    expect(dispatchSpy).toHaveBeenCalledWith('agents/get');
  });
});
