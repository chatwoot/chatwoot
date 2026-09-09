import { createStore } from 'vuex';
import { shallowMount } from '@vue/test-utils';
import FilterSelector from '../FilterSelector.vue';

describe('FilterSelector', () => {
  it('builds report bounds in the browser local timezone', () => {
    const wrapper = shallowMount(FilterSelector, {
      global: {
        mocks: { $t: message => message },
        plugins: [
          createStore({
            getters: { getReportFilters: () => ({}) },
            actions: { updateReportFilters: vi.fn() },
          }),
        ],
      },
    });

    const date = new Date(2026, 8, 9);
    const expected = new Date(2026, 8, 9, 9, 0, 0).getTime() / 1000;

    expect(wrapper.vm.getUnixWithTime(date, '09:00')).toBe(expected);
  });
});
