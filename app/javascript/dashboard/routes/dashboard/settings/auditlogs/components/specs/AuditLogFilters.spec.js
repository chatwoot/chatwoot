import { shallowMount } from '@vue/test-utils';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';
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

  it('emits a sort update', () => {
    const wrapper = mountComponent();
    wrapper.findComponent(SelectMenu).vm.$emit('update:modelValue', 'asc');

    expect(wrapper.emitted('update')).toEqual([[{ sort: 'asc' }]]);
  });

  it('clears the date window from the clear button', async () => {
    const wrapper = mountComponent({ since: 100, until: 200 });
    const clearButton = wrapper.findAllComponents(Button).at(1);
    await clearButton.trigger('click');

    expect(wrapper.emitted('update')).toEqual([
      [{ since: undefined, until: undefined }],
    ]);
  });

  it('applies a default window when enabling the date filter', async () => {
    const wrapper = mountComponent();
    const dateButton = wrapper.findAllComponents(Button).at(1);
    await dateButton.trigger('click');

    const [[payload]] = wrapper.emitted('update');
    expect(payload.since).toBeLessThan(payload.until);
  });
});
