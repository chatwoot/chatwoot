import { shallowMount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';

import Select from 'dashboard/components-next/select/Select.vue';
import DurationSelect from './DurationSelect.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: (key, { count }) => `${key}:${count}` }),
}));

const mountComponent = modelValue =>
  shallowMount(DurationSelect, {
    props: {
      modelValue,
      hoursAriaLabel: 'Hours',
      minutesAriaLabel: 'Minutes',
    },
  });

describe('DurationSelect', () => {
  it('shows the hour and minute parts of the duration', () => {
    const selects = mountComponent(75).findAllComponents(Select);

    expect(selects[0].props()).toMatchObject({
      modelValue: 1,
      ariaLabel: 'Hours',
    });
    expect(selects[1].props()).toMatchObject({
      modelValue: 15,
      ariaLabel: 'Minutes',
    });
  });

  it('combines changed hours and minutes into one value', async () => {
    const wrapper = mountComponent(75);
    const selects = wrapper.findAllComponents(Select);

    selects[0].vm.$emit('update:modelValue', 2);
    expect(wrapper.emitted('update:modelValue').at(-1)[0]).toBe(135);

    await wrapper.setProps({ modelValue: 135 });
    selects[1].vm.$emit('update:modelValue', 10);
    expect(wrapper.emitted('update:modelValue').at(-1)[0]).toBe(130);
  });

  it('keeps the duration within five minutes and one day', () => {
    const minimum = mountComponent(5);
    const zeroMinutes = minimum
      .findAllComponents(Select)[1]
      .props('options')
      .find(option => option.value === 0);
    expect(zeroMinutes.disabled).toBe(true);

    const maximum = mountComponent(1430);
    maximum.findAllComponents(Select)[0].vm.$emit('update:modelValue', 24);
    expect(maximum.emitted('update:modelValue').at(-1)[0]).toBe(1440);
  });
});
