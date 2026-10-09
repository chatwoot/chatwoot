import { shallowMount } from '@vue/test-utils';

import Copilot from '../Copilot.vue';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';

const mocks = vi.hoisted(() => ({
  isAdmin: { value: true },
  push: vi.fn(),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('vue-router', () => ({
  useRoute: () => ({ params: { accountId: '1' } }),
  useRouter: () => ({ push: mocks.push }),
}));

vi.mock('dashboard/composables', () => ({
  useTrack: vi.fn(),
}));

vi.mock('dashboard/composables/useAdmin', () => ({
  useAdmin: () => ({ isAdmin: mocks.isAdmin }),
}));

vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({ updateUISettings: vi.fn() }),
}));

const mountComponent = () =>
  shallowMount(Copilot, {
    props: { onSendMessage: vi.fn() },
    global: {
      mocks: { $t: key => key },
    },
  });

describe('Copilot', () => {
  beforeEach(() => {
    mocks.isAdmin.value = true;
    mocks.push.mockClear();
  });

  it('lets administrators open Copilot settings from the header', async () => {
    const wrapper = mountComponent();
    const header = wrapper.findComponent(SidebarActionsHeader);

    expect(header.props('buttons').map(button => button.key)).toEqual([
      'history',
      'new',
      'settings',
    ]);

    await header.vm.$emit('click', 'settings');

    expect(mocks.push).toHaveBeenCalledWith({
      name: 'copilot_settings_index',
      params: { accountId: '1' },
    });
  });

  it('hides Copilot settings from non-administrators', () => {
    mocks.isAdmin.value = false;

    const wrapper = mountComponent();
    const header = wrapper.findComponent(SidebarActionsHeader);

    expect(header.props('buttons').map(button => button.key)).toEqual([
      'history',
      'new',
    ]);
  });
});
