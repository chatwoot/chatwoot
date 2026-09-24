import { shallowMount } from '@vue/test-utils';
import MonitorChartFilters from '../MonitorChartFilters.vue';

vi.mock('vue-i18n', async importOriginal => ({
  ...(await importOriginal()),
  useI18n: () => ({ t: key => key }),
}));

const hide = vi.fn();
const global = {
  renderStubDefaultSlot: true,
  stubs: {
    Popover: {
      name: 'Popover',
      template: '<div><slot :is-open="true" /><slot name="content" /></div>',
      methods: { hide },
    },
  },
};

describe('MonitorChartFilters', () => {
  let wrapper;
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(new Date('2026-09-22T12:00:00Z'));
    hide.mockClear();
  });
  afterEach(() => {
    wrapper?.unmount();
    vi.useRealTimers();
  });

  it('limits custom dates to 7–30 days ending today', async () => {
    wrapper = shallowMount(MonitorChartFilters, {
      props: { modelValue: { range: 7, interval: 'day' }, timezone: 'UTC' },
      global,
    });
    wrapper.findComponent({ name: 'Popover' }).vm.$emit('show');
    await wrapper.find('select').setValue('custom');
    const inputs = wrapper.findAllComponents({ name: 'Input' });

    expect(inputs[0].attributes()).toMatchObject({
      min: '2026-08-24',
      max: '2026-09-16',
    });
    expect(inputs[1].attributes()).toMatchObject({
      min: '2026-09-22',
      max: '2026-09-22',
    });
  });

  it('uses the account-local date rather than UTC for the latest day', async () => {
    wrapper = shallowMount(MonitorChartFilters, {
      props: {
        modelValue: { range: 7, interval: 'day' },
        timezone: 'Pacific/Kiritimati',
      },
      global,
    });
    wrapper.findComponent({ name: 'Popover' }).vm.$emit('show');
    await wrapper.find('select').setValue('custom');

    expect(
      wrapper.findAllComponents({ name: 'Input' })[1].attributes('max')
    ).toBe('2026-09-23');
  });

  it('rejects dates after the pause date', async () => {
    wrapper = shallowMount(MonitorChartFilters, {
      props: {
        modelValue: { range: 7, interval: 'day' },
        timezone: 'UTC',
        pausedAt: Date.parse('2026-09-20T12:00:00Z') / 1000,
      },
      global,
    });
    wrapper.findComponent({ name: 'Popover' }).vm.$emit('show');
    await wrapper.find('select').setValue('custom');
    const inputs = wrapper.findAllComponents({ name: 'Input' });
    expect(inputs[1].attributes('max')).toBe('2026-09-20');

    inputs[1].vm.$emit('update:modelValue', '2026-09-21');
    await wrapper.find('form').trigger('submit');

    expect(wrapper.find('[role="alert"]').text()).toBe(
      'MONITORS.CUSTOM_RANGE_BOUNDARY_ERROR'
    );
    expect(wrapper.emitted('update:modelValue')).toBeUndefined();
  });

  it('rejects ranges outside 7–30 calendar days and applies valid ones', async () => {
    wrapper = shallowMount(MonitorChartFilters, {
      props: { modelValue: { range: 7, interval: 'day' }, timezone: 'UTC' },
      global,
    });
    wrapper.findComponent({ name: 'Popover' }).vm.$emit('show');
    await wrapper.find('select').setValue('custom');
    const inputs = wrapper.findAllComponents({ name: 'Input' });

    inputs[0].vm.$emit('update:modelValue', '2026-08-23');
    await wrapper.find('form').trigger('submit');
    expect(wrapper.find('[role="alert"]').text()).toBe(
      'MONITORS.CUSTOM_RANGE_HELP'
    );

    inputs[0].vm.$emit('update:modelValue', '2026-09-20');
    await wrapper.find('form').trigger('submit');
    expect(wrapper.emitted('update:modelValue')).toBeUndefined();

    inputs[0].vm.$emit('update:modelValue', '2026-08-24');
    await wrapper.find('form').trigger('submit');
    expect(wrapper.emitted('update:modelValue')).toEqual([
      [
        {
          range: 'custom',
          from: '2026-08-24',
          to: '2026-09-22',
          interval: 'day',
        },
      ],
    ]);
    expect(hide).toHaveBeenCalled();
  });

  it('keeps an unapplied draft when reopened and resets it when the applied filters change', async () => {
    wrapper = shallowMount(MonitorChartFilters, {
      props: { modelValue: { range: 30, interval: 'hour' }, timezone: 'UTC' },
      global,
    });
    wrapper.findComponent({ name: 'Popover' }).vm.$emit('show');
    await wrapper.vm.$nextTick();
    expect(wrapper.find('select').element.value).toBe('30');
    await wrapper.find('select').setValue('custom');

    wrapper.findComponent({ name: 'Popover' }).vm.$emit('show');
    await wrapper.vm.$nextTick();
    expect(wrapper.find('select').element.value).toBe('custom');

    await wrapper.setProps({ modelValue: { range: 7, interval: 'day' } });
    expect(wrapper.find('select').element.value).toBe('7');
  });
});
