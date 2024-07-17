import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import ReportsFiltersTeams from '../../Filters/Teams.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const mountParams = {
  mocks: {
    $t: msg => msg,
  },
  stubs: ['multiselect'],
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

    store = new Vuex.Store({
      modules: {
        teams: teamsModule,
      },
    });
  });

  it('dispatches "teams/get" action when component is mounted', () => {
    shallowMount(ReportsFiltersTeams, {
      store,
      localVue,
      ...mountParams,
    });
    expect(teamsModule.actions.get).toHaveBeenCalled();
  });

  it('emits "team-filter-selection" event when handleInput is called', () => {
    const wrapper = shallowMount(ReportsFiltersTeams, {
      store,
      localVue,
      ...mountParams,
    });
    wrapper.setData({ selectedOption: { id: 1, name: 'Team 1' } });
    wrapper.vm.handleInput();
    expect(wrapper.emitted('team-filter-selection')).toBeTruthy();
    expect(wrapper.emitted('team-filter-selection')[0]).toEqual([
      { id: 1, name: 'Team 1' },
    ]);
  });
});
