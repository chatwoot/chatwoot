import { shallowMount } from '@vue/test-utils';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import WootDatePicker from 'dashboard/components/ui/DatePicker/DatePicker.vue';
import AuditLogFilters from '../AuditLogFilters.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

let clickawayHandlers = [];

const mountComponent = (filters = {}) => {
  clickawayHandlers = [];
  return shallowMount(AuditLogFilters, {
    props: { filters },
    global: {
      mocks: { $t: key => key },
      directives: {
        'on-clickaway': {
          mounted: (el, binding) => clickawayHandlers.push(binding.value),
        },
      },
    },
  });
};

describe('AuditLogFilters', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('auto-searches after a pause for three or more characters', async () => {
    const wrapper = mountComponent();
    const input = wrapper.findComponent(Input);
    await input.vm.$emit('update:modelValue', 'vis');

    expect(wrapper.emitted('update')).toBeUndefined();

    vi.advanceTimersByTime(800);
    expect(wrapper.emitted('update')).toEqual([[{ q: 'vis' }]]);
  });

  it('does not auto-search below three characters', async () => {
    const wrapper = mountComponent();
    const input = wrapper.findComponent(Input);
    await input.vm.$emit('update:modelValue', 'vi');
    vi.advanceTimersByTime(800);

    expect(wrapper.emitted('update')).toBeUndefined();
  });

  it('searches immediately on enter regardless of length', async () => {
    const wrapper = mountComponent();
    const input = wrapper.findComponent(Input);
    await input.vm.$emit('update:modelValue', 'vi');
    await input.vm.$emit('enter');

    expect(wrapper.emitted('update')).toEqual([[{ q: 'vi' }]]);
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
        new Date(2026, 7, 1),
        new Date(2026, 7, 10),
        'last30days',
      ]);
    await wrapper.vm.$nextTick();

    const [[payload]] = wrapper.emitted('update');
    expect(payload.since).toBeLessThan(payload.until);
    expect(wrapper.findComponent(WootDatePicker).props('rangeType')).toBe(
      'last30days'
    );
  });

  it('discards unapplied picker edits when dismissed', async () => {
    const wrapper = mountComponent({ since: 100, until: 200 });
    const before = wrapper.findComponent(WootDatePicker).vm;

    clickawayHandlers.forEach(handler => handler());
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('update')).toBeUndefined();
    expect(wrapper.findComponent(WootDatePicker).vm).not.toBe(before);
  });

  it('closes the picker when it is dismissed with nothing applied', async () => {
    const wrapper = mountComponent();
    await wrapper.findAllComponents(Button).at(2).trigger('click');
    expect(wrapper.findComponent(WootDatePicker).exists()).toBe(true);

    wrapper.findComponent(WootDatePicker).vm.$emit('close');
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('update')).toBeUndefined();
    expect(wrapper.findComponent(WootDatePicker).exists()).toBe(false);
  });

  it('widens a picked range to whole days', async () => {
    const wrapper = mountComponent();
    await wrapper.findAllComponents(Button).at(2).trigger('click');
    wrapper
      .findComponent(WootDatePicker)
      .vm.$emit('dateRangeChanged', [
        new Date(2026, 7, 1, 13, 4, 5),
        new Date(2026, 7, 10, 13, 4, 5),
      ]);

    const [[payload]] = wrapper.emitted('update');
    expect(new Date(payload.since * 1000)).toEqual(
      new Date(2026, 7, 1, 0, 0, 0)
    );
    expect(new Date(payload.until * 1000)).toEqual(
      new Date(2026, 7, 10, 23, 59, 59)
    );
  });
});
