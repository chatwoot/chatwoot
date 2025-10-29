import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import ReportsFiltersTeams from '../../Filters/Teams.vue';

const mountParams = {
  global: {
    mocks: {
      $t: msg => msg,
    },
    stubs: ['multiselect'],
  },
};

describe('ReportsFiltersTeams.vue', () => {
  let store;
  let teamsModule;

  beforeEach(() => {
    teamsModule = {
      namespaced: true,
      getters: {
        getTeams: () => () => [
          { id: 1, name: 'Team 1' },
          { id: 2, name: 'Team 2' },
        ],
      },
      actions: {
        get: vi.fn(),
      },
    };

    store = createStore({
      modules: {
        teams: teamsModule,
      },
    });
  });

  it('dispatches "teams/get" action when component is mounted', () => {
    shallowMount(ReportsFiltersTeams, {
      global: {
        plugins: [store],
        ...mountParams,
      },
    });
    expect(teamsModule.actions.get).toHaveBeenCalled();
  });

  it('emits "team-filter-selection" event when handleInput is called', async () => {
    const wrapper = shallowMount(ReportsFiltersTeams, {
      global: {
        plugins: [store],
        ...mountParams,
      },
    });

    await wrapper.setData({ selectedOption: { id: 1, name: 'Team 1' } });
    await wrapper.vm.handleInput();

    expect(wrapper.emitted('teamFilterSelection')).toBeTruthy();
    expect(wrapper.emitted('teamFilterSelection')[0]).toEqual([
      { id: 1, name: 'Team 1' },
    ]);
  });
});
