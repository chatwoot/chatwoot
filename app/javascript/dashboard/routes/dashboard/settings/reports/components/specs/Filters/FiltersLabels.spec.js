import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import ReportsFiltersLabels from '../../Filters/Labels.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const mountParams = {
  mocks: {
    $t: msg => msg,
  },
  stubs: ['multiselect'],
};

describe('ReportsFiltersLabels.vue', () => {
  let store;
  let labelsModule;

  beforeEach(() => {
    labelsModule = {
      namespaced: true,
      getters: {
        getLabels: () => () => [
          { id: 1, title: 'Label 1', color: 'red' },
          { id: 2, title: 'Label 2', color: 'blue' },
        ],
      },
      actions: {
        get: vi.fn(),
      },
    };

    store = new Vuex.Store({
      modules: {
        labels: labelsModule,
      },
    });
  });

  it('dispatches "labels/get" action when component is mounted', () => {
    shallowMount(ReportsFiltersLabels, {
      store,
      localVue,
      ...mountParams,
    });
    expect(labelsModule.actions.get).toHaveBeenCalled();
  });

  it('emits "labels-filter-selection" event when handleInput is called', () => {
    const wrapper = shallowMount(ReportsFiltersLabels, {
      store,
      localVue,
      ...mountParams,
    });

    const selectedLabel = { id: 1, title: 'Label 1', color: 'red' };
    wrapper.setData({ selectedOption: selectedLabel });

    wrapper.vm.handleInput();

    expect(wrapper.emitted('labels-filter-selection')).toBeTruthy();
    expect(wrapper.emitted('labels-filter-selection')[0]).toEqual([
      selectedLabel,
    ]);
  });
});
