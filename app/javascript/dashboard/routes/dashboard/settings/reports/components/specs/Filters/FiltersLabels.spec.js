import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import ReportsFiltersLabels from '../../Filters/Labels.vue';

const mountParams = {
  global: {
    mocks: {
      $t: msg => msg,
    },
    stubs: ['multiselect'],
  },
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

    store = createStore({
      modules: {
        labels: labelsModule,
      },
    });
  });

  it('dispatches "labels/get" action when component is mounted', () => {
    shallowMount(ReportsFiltersLabels, {
      global: {
        plugins: [store],
        ...mountParams.global,
      },
    });
    expect(labelsModule.actions.get).toHaveBeenCalled();
  });

  it('emits "labels-filter-selection" event when handleInput is called', async () => {
    const wrapper = shallowMount(ReportsFiltersLabels, {
      global: {
        plugins: [store],
        ...mountParams.global,
      },
    });

    const selectedLabel = { id: 1, title: 'Label 1', color: 'red' };
    await wrapper.setData({ selectedOption: selectedLabel });

    await wrapper.vm.handleInput();

    expect(wrapper.emitted('labelsFilterSelection')).toBeTruthy();
    expect(wrapper.emitted('labelsFilterSelection')[0]).toEqual([
      selectedLabel,
    ]);
  });
});
