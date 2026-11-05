import { shallowMount } from '@vue/test-utils';
import ContactInfoRow from '../ContactInfoRow.vue';

const mountComponent = (props, slots = {}) =>
  shallowMount(ContactInfoRow, {
    props: { icon: 'map', emoji: '🌍', ...props },
    slots,
    global: { mocks: { $t: key => key } },
  });

describe('ContactInfoRow', () => {
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
