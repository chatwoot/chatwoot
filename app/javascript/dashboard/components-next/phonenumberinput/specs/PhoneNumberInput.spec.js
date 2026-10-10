import { describe, it, expect } from 'vitest';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import PhoneNumberInput from '../PhoneNumberInput.vue';

describe('PhoneNumberInput.vue', () => {
  const createWrapper = (props = {}) => {
    return mount(PhoneNumberInput, {
      props,
      global: {
        directives: {
          'on-clickaway': () => {},
        },
      },
    });
  };

  it('initializes and formats US phone number from E.164 modelValue', async () => {
    const wrapper = createWrapper({
      modelValue: '+12025550123',
    });
    await nextTick();

    const input = wrapper.find('input[type="tel"]');
    expect(input.element.value).toBe('(202) 555-0123');
    expect(wrapper.text()).toContain('+1');
    expect(wrapper.find('.text-n-ruby-9').exists()).toBe(false);
  });

  it('initializes and formats Turkish phone number from E.164 modelValue', async () => {
    const wrapper = createWrapper({
      modelValue: '+905321234567',
    });
    await nextTick();

    const input = wrapper.find('input[type="tel"]');
    expect(input.element.value).toBe('532 123 45 67');
    expect(wrapper.text()).toContain('+90');
    expect(wrapper.find('.text-n-ruby-9').exists()).toBe(false);
  });

  it('formats as-you-type for US and emits clean E.164 without parentheses or spaces', async () => {
    const wrapper = createWrapper({
      modelValue: '+12025550000',
    });
    await nextTick();

    const input = wrapper.find('input[type="tel"]');
    await input.setValue('2025550123');
    await nextTick();

    // Visual formatting inside input should have parentheses for US
    expect(input.element.value).toBe('(202) 555-0123');
    // Emitted value must be pure E.164 without parentheses
    expect(wrapper.emitted('update:modelValue')).toBeTruthy();
    const emittedValues = wrapper.emitted('update:modelValue').flat();
    expect(emittedValues).toContain('+12025550123');
    // Error message must not be shown
    expect(wrapper.find('.text-n-ruby-9').exists()).toBe(false);
  });

  it('formats as-you-type for TR and emits clean E.164', async () => {
    const wrapper = createWrapper({
      modelValue: '+905320000000',
    });
    await nextTick();

    const input = wrapper.find('input[type="tel"]');
    await input.setValue('5321234567');
    await nextTick();

    expect(input.element.value).toBe('532 123 45 67');
    const emittedValues = wrapper.emitted('update:modelValue').flat();
    expect(emittedValues).toContain('+905321234567');
    expect(wrapper.find('.text-n-ruby-9').exists()).toBe(false);
  });

  it('detects country and formats when user pastes a full international number with +', async () => {
    const wrapper = createWrapper({
      modelValue: '',
    });
    await nextTick();

    const input = wrapper.find('input[type="tel"]');
    await input.setValue('+90 532 123 45 67');
    await nextTick();

    expect(wrapper.text()).toContain('+90');
    expect(input.element.value).toBe('532 123 45 67');
  });

  it('detects US country and formats when user pastes a full US number with +', async () => {
    const wrapper = createWrapper({
      modelValue: '',
    });
    await nextTick();

    const input = wrapper.find('input[type="tel"]');
    await input.setValue('+1 202 555 0123');
    await nextTick();

    expect(wrapper.text()).toContain('+1');
    expect(input.element.value).toBe('(202) 555-0123');
    expect(wrapper.find('.text-n-ruby-9').exists()).toBe(false);
  });

  it('formats as-you-type for Afghanistan (+93) correctly', async () => {
    const wrapper = createWrapper({
      modelValue: '+93701234567',
    });
    await nextTick();

    const input = wrapper.find('input[type="tel"]');
    expect(input.element.value).toBe('70 123 4567');
    expect(wrapper.text()).toContain('+93');
    expect(wrapper.find('.text-n-ruby-9').exists()).toBe(false);
  });

  it('does not format and shows error when entering invalid characters like 1-800-FLOWERS', async () => {
    const wrapper = createWrapper({
      modelValue: '',
    });
    await nextTick();

    const input = wrapper.find('input[type="tel"]');
    await input.setValue('1-800-FLOWERS');
    await nextTick();

    expect(input.element.value).toBe('1-800-FLOWERS');
    expect(wrapper.find('.text-n-ruby-9').exists()).toBe(true);
    expect(wrapper.emitted('update:modelValue')).toBeFalsy();
  });
});
