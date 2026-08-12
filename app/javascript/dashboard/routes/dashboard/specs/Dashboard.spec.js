import { computed, h, nextTick, onMounted, onUnmounted, ref } from 'vue';
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

const createUpgradePageStub = paywalled => ({
  name: 'UpgradePage',
  props: { bypassUpgradePage: { type: Boolean, default: false } },
  setup(props, { expose, slots }) {
    expose({
      isAccountPaywalled: computed(() => paywalled.value),
      shouldShowUpgradePage: computed(
        () => !props.bypassUpgradePage && paywalled.value
      ),
    });
    return () => h('div', { class: 'upgrade-page' }, slots.default?.());
  },
});

// ninja-keys binds cmd+k / ctrl+k when it connects and unbinds when it
// disconnects, so the hotkey only works while the component stays mounted.
const createCommandBarStub = tracker => ({
  name: 'CommandBar',
  props: { isPaywalled: { type: Boolean, default: false } },
  setup(props) {
    tracker.mounts += 1;
    const onKeydown = event => {
      if (event.key === 'k' && (event.metaKey || event.ctrlKey)) {
        tracker.opens += 1;
      }
    };
    onMounted(() => document.addEventListener('keydown', onKeydown));
    onUnmounted(() => document.removeEventListener('keydown', onKeydown));
    return () =>
      h('div', {
        class: 'command-bar',
        'data-paywalled': String(props.isPaywalled),
      });
  },
});

const pressHotkey = (modifier = 'metaKey') =>
  document.dispatchEvent(
    new KeyboardEvent('keydown', { key: 'k', [modifier]: true })
  );

describe('Dashboard', () => {
  let wrapper;

  const mountDashboard = async ({
    paywalled = false,
    routeName = 'home',
  } = {}) => {
    const isPaywalled = ref(paywalled);
    const commandBar = { mounts: 0, opens: 0 };
    const router = createRouter({
      history: createMemoryHistory(),
      routes: ROUTES,
    });
    await router.push({ name: routeName });
    await router.isReady();

    wrapper = mount(Dashboard, {
      global: {
        plugins: [router],
        stubs: {
          UpgradePage: createUpgradePageStub(isPaywalled),
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

    return { wrapper, router, isPaywalled, commandBar };
  };

  const isCommandBarPaywalled = () =>
    wrapper.find('.command-bar').attributes('data-paywalled') === 'true';

  afterEach(() => {
    wrapper?.unmount();
  });

  describe('when the account is not paywalled', () => {
    it('renders the routed content and keeps the upgrade page hidden', async () => {
      await mountDashboard();

      expect(wrapper.find('.routed-content').exists()).toBe(true);
      expect(wrapper.find('.upgrade-page').isVisible()).toBe(false);
    });

    it('mounts the command bar', async () => {
      const { commandBar } = await mountDashboard();

      expect(wrapper.find('.command-bar').exists()).toBe(true);
      expect(commandBar.mounts).toBe(1);
    });

    it('marks the command bar as not paywalled', async () => {
      await mountDashboard();

      expect(isCommandBarPaywalled()).toBe(false);
    });
  });

  describe('when the account is paywalled', () => {
    it('replaces the routed content with the upgrade page', async () => {
      await mountDashboard({ paywalled: true });

      expect(wrapper.find('.routed-content').exists()).toBe(false);
      expect(wrapper.find('.upgrade-page').isVisible()).toBe(true);
    });

    it('keeps the command bar mounted', async () => {
      const { commandBar } = await mountDashboard({ paywalled: true });

      expect(wrapper.find('.command-bar').exists()).toBe(true);
      expect(commandBar.mounts).toBe(1);
    });

    it('marks the command bar as paywalled', async () => {
      await mountDashboard({ paywalled: true });

      expect(isCommandBarPaywalled()).toBe(true);
    });

    it.each(['metaKey', 'ctrlKey'])('opens on %s + k', async modifier => {
      const { commandBar } = await mountDashboard({ paywalled: true });

      pressHotkey(modifier);

      expect(commandBar.opens).toBe(1);
    });
  });

  describe('across the paywall transition', () => {
    it('does not remount the command bar when the upgrade page takes over', async () => {
      const { isPaywalled, commandBar } = await mountDashboard();

      isPaywalled.value = true;
      await nextTick();

      expect(wrapper.find('.routed-content').exists()).toBe(false);
      expect(wrapper.find('.command-bar').exists()).toBe(true);
      expect(commandBar.mounts).toBe(1);
      expect(isCommandBarPaywalled()).toBe(true);
    });

    it('keeps handling the hotkey after the upgrade page takes over', async () => {
      const { isPaywalled, commandBar } = await mountDashboard();

      pressHotkey();
      isPaywalled.value = true;
      await nextTick();
      pressHotkey();

      expect(commandBar.opens).toBe(2);
    });

    it('restores the routed content when the paywall clears', async () => {
      const { isPaywalled, commandBar } = await mountDashboard({
        paywalled: true,
      });

      isPaywalled.value = false;
      await nextTick();

      expect(wrapper.find('.routed-content').exists()).toBe(true);
      expect(wrapper.find('.command-bar').exists()).toBe(true);
      expect(commandBar.mounts).toBe(1);
      expect(isCommandBarPaywalled()).toBe(false);
    });
  });

  describe('on a route that bypasses the upgrade page', () => {
    it('keeps the routed content while the account is paywalled', async () => {
      await mountDashboard({
        paywalled: true,
        routeName: 'billing_settings_index',
      });

      expect(wrapper.find('.routed-content').exists()).toBe(true);
      expect(wrapper.find('.upgrade-page').isVisible()).toBe(false);
    });

    it('still marks the command bar as paywalled', async () => {
      await mountDashboard({
        paywalled: true,
        routeName: 'billing_settings_index',
      });

      expect(isCommandBarPaywalled()).toBe(true);
    });

    it('keeps one command bar when navigating away from the upgrade page', async () => {
      const { router, commandBar } = await mountDashboard({ paywalled: true });

      await router.push({ name: 'billing_settings_index' });
      await flushPromises();

      expect(wrapper.find('.routed-content').exists()).toBe(true);
      expect(commandBar.mounts).toBe(1);
      expect(isCommandBarPaywalled()).toBe(true);
    });
  });
});
