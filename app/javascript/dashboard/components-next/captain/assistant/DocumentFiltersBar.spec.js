import { mount } from '@vue/test-utils';
import DocumentFiltersBar from './DocumentFiltersBar.vue';

const { checkPermissions } = vi.hoisted(() => ({
  checkPermissions: vi.fn(() => true),
}));

vi.mock('dashboard/composables/usePolicy', () => ({
  usePolicy: () => ({ checkPermissions }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key.split('.').at(-1).replaceAll('_', ' '),
  }),
}));

const ButtonStub = {
  props: ['icon'],
  emits: ['click'],
  template: '<button @click="$emit(\'click\')"><slot /></button>',
};

const DropdownMenuStub = {
  props: ['menuItems'],
  emits: ['action'],
  template: '<div data-test="dropdown-menu" />',
};

const mountFilterBar = () =>
  mount(DocumentFiltersBar, {
    global: {
      stubs: {
        Button: ButtonStub,
        DropdownMenu: DropdownMenuStub,
        Icon: true,
      },
    },
  });

describe('DocumentFiltersBar', () => {
  beforeEach(() => {
    checkPermissions.mockReturnValue(true);
  });

  it('sorts documents by conversation usage from the existing sort menu', async () => {
    const wrapper = mountFilterBar();
    const buttons = wrapper.findAllComponents(ButtonStub);

    await buttons.at(-1).trigger('click');

    const dropdown = wrapper.getComponent(DropdownMenuStub);
    expect(dropdown.props('menuItems')).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          label: 'MOST USED',
          value: 'most_used',
          icon: 'i-lucide-messages-square',
        }),
      ])
    );

    dropdown.vm.$emit('action', { action: 'sort', value: 'most_used' });
    expect(wrapper.emitted('selectSort')).toEqual([['most_used']]);
  });

  it('hides conversation usage sorting from agents', async () => {
    checkPermissions.mockReturnValue(false);
    const wrapper = mountFilterBar();
    const buttons = wrapper.findAllComponents(ButtonStub);

    await buttons.at(-1).trigger('click');

    const dropdown = wrapper.getComponent(DropdownMenuStub);
    expect(dropdown.props('menuItems')).not.toEqual(
      expect.arrayContaining([expect.objectContaining({ value: 'most_used' })])
    );
  });
});
