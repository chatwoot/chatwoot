import { shallowMount } from '@vue/test-utils';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import WootDatePicker from 'dashboard/components/ui/DatePicker/DatePicker.vue';
import AuditLogFilters from '../AuditLogFilters.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const mountComponent = (filters = {}) =>
  shallowMount(AuditLogFilters, {
    props: { filters },
    global: {
      mocks: { $t: key => key },
      directives: { 'on-clickaway': {} },
    },
  });

describe('AuditLogFilters', () => {
  it('searches only on enter, not while typing', async () => {
    const wrapper = mountComponent();
    const input = wrapper.findComponent(Input);
    await input.vm.$emit('update:modelValue', 'v');
    await input.vm.$emit('update:modelValue', 'vishnu');

    expect(wrapper.emitted('update')).toBeUndefined();

    await input.vm.$emit('enter');
    expect(wrapper.emitted('update')).toEqual([[{ q: 'vishnu' }]]);
  });

  it('clears the search filter when the input is emptied', async () => {
    const wrapper = mountComponent({ q: 'jane' });
    const input = wrapper.findComponent(Input);
    await input.vm.$emit('update:modelValue', '');

    expect(wrapper.emitted('update')).toEqual([[{ q: undefined }]]);
  });

  it('emits a type update when an event type is chosen', async () => {
    const wrapper = mountComponent();
    await wrapper.findComponent(Button).trigger('click');
    wrapper.findComponent(DropdownMenu).vm.$emit('action', { value: 'Inbox' });

    expect(wrapper.emitted('update')).toEqual([[{ type: 'Inbox' }]]);
  });

  it('clears the type when all events is chosen', async () => {
    const wrapper = mountComponent({ type: 'Inbox' });
    await wrapper.findComponent(Button).trigger('click');
    wrapper.findComponent(DropdownMenu).vm.$emit('action', { value: '' });

    expect(wrapper.emitted('update')).toEqual([[{ type: undefined }]]);
  });

  it('emits a sort update from the sort menu', async () => {
    const wrapper = mountComponent();
    const sortButton = wrapper.findAllComponents(Button).at(1);
    await sortButton.trigger('click');
    wrapper.findComponent(DropdownMenu).vm.$emit('action', { value: 'asc' });

    expect(wrapper.emitted('update')).toEqual([[{ sort: 'asc' }]]);
  });

  it('clears the date window from the clear button', async () => {
    const wrapper = mountComponent({ since: 100, until: 200 });
    const clearButton = wrapper.findAllComponents(Button).at(2);
    await clearButton.trigger('click');

    expect(wrapper.emitted('update')).toEqual([
      [{ since: undefined, until: undefined }],
    ]);
  });

  it('opens the picker without applying any filter', async () => {
    const wrapper = mountComponent();
    expect(wrapper.findComponent(WootDatePicker).exists()).toBe(false);

    const dateButton = wrapper.findAllComponents(Button).at(2);
    await dateButton.trigger('click');

    expect(wrapper.emitted('update')).toBeUndefined();
    expect(wrapper.findComponent(WootDatePicker).exists()).toBe(true);
  });

  it('applies the range picked in the date picker and keeps its range type', async () => {
    const wrapper = mountComponent();
    await wrapper.findAllComponents(Button).at(2).trigger('click');
    wrapper
      .findComponent(WootDatePicker)
      .vm.$emit('dateRangeChanged', [
        new Date(1000),
        new Date(2000),
        'last30days',
      ]);
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('update')).toEqual([[{ since: 1, until: 2 }]]);
    expect(wrapper.findComponent(WootDatePicker).props('rangeType')).toBe(
      'last30days'
    );
  });
});
