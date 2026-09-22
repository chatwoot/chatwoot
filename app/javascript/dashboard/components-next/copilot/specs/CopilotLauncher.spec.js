import { ref } from 'vue';
import { shallowMount } from '@vue/test-utils';
import CopilotLauncher from '../CopilotLauncher.vue';

const state = vi.hoisted(() => ({ enabledFlags: [], routeName: 'dashboard' }));
vi.mock('vue-router', () => ({ useRoute: () => ({ name: state.routeName }) }));
vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({ uiSettings: ref({}), updateUISettings: vi.fn() }),
}));
vi.mock('dashboard/composables/store', () => ({
  useMapGetter: key =>
    ref(
      key === 'getCurrentAccountId'
        ? 1
        : (_, flag) => state.enabledFlags.includes(flag)
    ),
}));

describe('Copilot launcher flags', () => {
  it.each([
    { flags: ['copilot_v2'], route: 'inbox_conversation', visible: true },
    { flags: ['captain_integration'], route: 'dashboard', visible: true },
    {
      flags: ['captain_integration'],
      route: 'inbox_conversation',
      visible: false,
    },
    { flags: [], route: 'dashboard', visible: false },
  ])('shows $visible for $flags on $route', ({ flags, route, visible }) => {
    state.enabledFlags = flags;
    state.routeName = route;
    const wrapper = shallowMount(CopilotLauncher);
    expect(wrapper.find('div').exists()).toBe(visible);
    wrapper.unmount();
  });
});
