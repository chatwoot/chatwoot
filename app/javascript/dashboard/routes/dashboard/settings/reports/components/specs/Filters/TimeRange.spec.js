import { shallowMount } from '@vue/test-utils';
import ReportsFiltersTimeRange from '../../Filters/TimeRange.vue';

describe('ReportsFiltersTimeRange.vue', () => {
  const mountComponent = () =>
    shallowMount(ReportsFiltersTimeRange, {
      global: {
        mocks: {
          $t: msg => msg,
        },
      },
    });

  it('emits "timeRangeChanged" immediately on mount with default values', () => {
    const wrapper = mountComponent();

    expect(wrapper.emitted('timeRangeChanged')).toBeTruthy();
    expect(wrapper.emitted('timeRangeChanged')[0]).toEqual([
      {
        since: '00:00',
        until: '23:59',
      },
    ]);
  });

  it('emits "timeRangeChanged" when timeFrom changes', async () => {
    const wrapper = mountComponent();

    await wrapper.find('input[type="time"]').setValue('08:30');

    const emitted = wrapper.emitted('timeRangeChanged');

    expect(emitted.at(-1)).toEqual([
      {
        since: '08:30',
        until: '23:59',
      },
    ]);
  });

  it('emits "timeRangeChanged" when timeTo changes', async () => {
    const wrapper = mountComponent();

    const inputs = wrapper.findAll('input[type="time"]');
    await inputs[1].setValue('18:45');

    const emitted = wrapper.emitted('timeRangeChanged');

    expect(emitted.at(-1)).toEqual([
      {
        since: '00:00',
        until: '18:45',
      },
    ]);
  });

  it('emits correct payload when both times are changed', async () => {
    const wrapper = mountComponent();

    const inputs = wrapper.findAll('input[type="time"]');

    await inputs[0].setValue('09:00');
    await inputs[1].setValue('17:00');

    const emitted = wrapper.emitted('timeRangeChanged');

    expect(emitted.at(-1)).toEqual([
      {
        since: '09:00',
        until: '17:00',
      },
    ]);
  });
});
