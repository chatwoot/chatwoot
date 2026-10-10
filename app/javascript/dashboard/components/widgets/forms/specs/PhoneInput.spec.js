import { describe, it, expect } from 'vitest';
import { shallowMount } from '@vue/test-utils';
import PhoneInput from '../PhoneInput.vue';

describe('PhoneInput.vue', () => {
  const createWrapper = (props = {}) => {
    return shallowMount(PhoneInput, {
      props: {
        modelValue: '',
        ...props,
      },
      global: {
        mocks: {
          $t: key => key,
        },
        directives: {
          'on-clickaway': () => {},
        },
        stubs: {
          'fluent-icon': true,
        },
      },
    });
  };

  it('formats valid phone input on change', async () => {
    const wrapper = createWrapper();
    wrapper.vm.activeCountryCode = 'US';
    wrapper.vm.activeDialCode = '+1';

    const input = wrapper.find('input[type="tel"]');
    await input.setValue('2025550123');
    await input.trigger('input');

    expect(wrapper.vm.phoneNumber).toBe('(202) 555-0123');
    expect(wrapper.emitted('update:modelValue')[0]).toEqual(['2025550123']);
  });

  it('preserves raw input and does not strip characters when entering invalid text like 1-800-FLOWERS', async () => {
    const wrapper = createWrapper();
    wrapper.vm.activeCountryCode = 'US';
    wrapper.vm.activeDialCode = '+1';

    const input = wrapper.find('input[type="tel"]');
    await input.setValue('1-800-FLOWERS');
    await input.trigger('input');

    expect(wrapper.vm.phoneNumber).toBe('1-800-FLOWERS');
    expect(wrapper.emitted('update:modelValue')[0]).toEqual(['1-800-FLOWERS']);
  });

  it('preserves raw invalid input when changing country', async () => {
    const wrapper = createWrapper();
    wrapper.vm.phoneNumber = '1-800-FLOWERS';
    wrapper.vm.showDropdown = true;

    wrapper.vm.onSelectCountry({
      id: 'GB',
      name: 'United Kingdom',
      dial_code: '+44',
      emoji: '🇬🇧',
    });

    expect(wrapper.vm.phoneNumber).toBe('1-800-FLOWERS');
    expect(wrapper.emitted('update:modelValue')[0]).toEqual(['1-800-FLOWERS']);
  });
});
