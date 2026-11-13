import { describe, it, expect, vi } from 'vitest';
import { shallowMount } from '@vue/test-utils';
import ContactInfoRow from '../ContactInfoRow.vue';

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

vi.mock('shared/helpers/clipboard', () => ({
  copyTextToClipboard: vi.fn(),
}));

const mountComponent = (props = {}, slots = {}) =>
  shallowMount(ContactInfoRow, {
    props: {
      icon: 'call',
      emoji: '📞',
      ...props,
    },
    slots,
    global: {
      mocks: {
        $t: key => key,
      },
    },
  });

describe('ContactInfoRow', () => {
  it('renders raw value when displayValue is not provided', () => {
    const wrapper = mountComponent({
      value: '+905321234567',
      href: 'tel:+905321234567',
    });

    expect(wrapper.text()).toContain('+905321234567');
    expect(wrapper.find('a').attributes('href')).toBe('tel:+905321234567');
  });

  it('renders displayValue when provided while keeping href on raw value', () => {
    const wrapper = mountComponent({
      value: '+905321234567',
      displayValue: '+90 532 123 45 67',
      href: 'tel:+905321234567',
    });

    expect(wrapper.text()).toContain('+90 532 123 45 67');
    expect(wrapper.find('a').attributes('href')).toBe('tel:+905321234567');
  });

  it('shows NOT_AVAILABLE when value is empty', () => {
    const wrapper = mountComponent({
      value: '',
    });

    expect(wrapper.text()).toContain('CONTACT_PANEL.NOT_AVAILABLE');
  });

  it('does not drop characters when editValue contains letters', async () => {
    const wrapper = mountComponent({
      value: '+18001234567',
      displayValue: '+1 800 123 4567',
      editable: true,
    });

    wrapper.vm.startEditing();
    wrapper.vm.editValue = '+1 800 FLOWERS';
    await wrapper.vm.$nextTick();

    expect(wrapper.vm.editValue).toBe('+1 800 FLOWERS');
  });

  const markup = '<form><input name="field"></form><img src="x">Acme';

  it('renders values without a link as plain text', () => {
    const wrapper = mountComponent({ value: markup });

    expect(wrapper.find('form').exists()).toBe(false);
    expect(wrapper.find('input').exists()).toBe(false);
    expect(wrapper.find('img').exists()).toBe(false);
    expect(wrapper.text()).toContain(markup);
  });

  it('renders slot content next to the value', () => {
    const wrapper = mountComponent(
      { value: 'Northtown, Northland' },
      { default: '<span class="flag" />' }
    );

    expect(wrapper.find('.flag').exists()).toBe(true);
  });
});
