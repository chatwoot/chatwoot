import { describe, it, expect, vi } from 'vitest';
import { shallowMount } from '@vue/test-utils';
import ContactInfoRow from '../ContactInfoRow.vue';

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

vi.mock('shared/helpers/clipboard', () => ({
  copyTextToClipboard: vi.fn(),
}));

const mountComponent = (props = {}) =>
  shallowMount(ContactInfoRow, {
    props: {
      icon: 'call',
      emoji: '📞',
      ...props,
    },
    global: {
      mocks: {
        $t: key => key,
      },
      directives: {
        'dompurify-html': () => {},
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
});
