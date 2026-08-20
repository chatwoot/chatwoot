import { h, nextTick, onMounted, onUnmounted } from 'vue';
import { createMemoryHistory, createRouter } from 'vue-router';
import { flushPromises, mount } from '@vue/test-utils';
import Dashboard from '../Dashboard.vue';

vi.mock('dashboard/composables/useUISettings', async () => {
  const { ref: createRef } = await import('vue');
  return {
    useUISettings: () => ({
      uiSettings: createRef({}),
      updateUISettings: vi.fn(),
    }),
  };
});

vi.mock('dashboard/composables/useAccount', async () => {
  const { ref: createRef } = await import('vue');
  return { useAccount: () => ({ accountId: createRef(1) }) };
});

vi.mock('dashboard/stores/calls', () => ({
  useCallsStore: () => ({ hasActiveCall: false, hasIncomingCall: false }),
}));

const RoutedContent = { template: '<div class="routed-content" />' };

const ROUTES = [
  { path: '/', name: 'home', component: RoutedContent },
  {
    path: '/billing',
    name: 'billing_settings_index',
    component: RoutedContent,
  },
];

// ninja-keys binds cmd+k / ctrl+k when it connects and unbinds when it
// disconnects, so the hotkey only works while the component stays mounted.
const createCommandBarStub = tracker => ({
  name: 'CommandBar',
  setup() {
    tracker.mounts += 1;
    const onKeydown = event => {
      if (event.key === 'k' && (event.metaKey || event.ctrlKey)) {
        tracker.opens += 1;
      }
    };
    onMounted(() => document.addEventListener('keydown', onKeydown));
    onUnmounted(() => document.removeEventListener('keydown', onKeydown));
    return () => h('div', { class: 'command-bar' });
  },
});

const pressHotkey = (modifier = 'metaKey') =>
  document.dispatchEvent(
    new KeyboardEvent('keydown', { key: 'k', [modifier]: true })
  );

describe('Dashboard', () => {
  let wrapper;

  const mountDashboard = async () => {
    const commandBar = { mounts: 0, opens: 0 };
    const router = createRouter({
      history: createMemoryHistory(),
      routes: ROUTES,
    });
    await router.push({ name: 'home' });
    await router.isReady();

    wrapper = mount(Dashboard, {
      global: {
        plugins: [router],
        stubs: {
          CommandBar: createCommandBarStub(commandBar),
          NextSidebar: true,
          MobileSidebarLauncher: true,
          CopilotLauncher: true,
          CopilotContainer: true,
          FloatingCallWidget: true,
          AddAccountModal: true,
          WootKeyShortcutModal: true,
        },
      },
    });
    await flushPromises();

    return { wrapper, router, commandBar };
  };

  afterEach(() => {
    wrapper?.unmount();
  });

  it('renders the routed content', async () => {
    await mountDashboard();

    expect(wrapper.find('.routed-content').exists()).toBe(true);
  });

  it('mounts the command bar once', async () => {
    const { commandBar } = await mountDashboard();

    expect(wrapper.find('.command-bar').exists()).toBe(true);
    expect(commandBar.mounts).toBe(1);
  });

  it.each(['metaKey', 'ctrlKey'])('opens on %s + k', async modifier => {
    const { commandBar } = await mountDashboard();

    pressHotkey(modifier);

    expect(commandBar.opens).toBe(1);
  });

  it('keeps handling the hotkey across re-renders', async () => {
    const { commandBar } = await mountDashboard();

    pressHotkey();
    await nextTick();
    pressHotkey();

    expect(commandBar.opens).toBe(2);
  });
});
