<script setup>
import {
  defineAsyncComponent,
  ref,
  computed,
  onMounted,
  onUnmounted,
  nextTick,
  watch,
} from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';

import NextSidebar from 'next/sidebar/Sidebar.vue';
import WootKeyShortcutModal from 'dashboard/components/widgets/modal/WootKeyShortcutModal.vue';
import AddAccountModal from 'dashboard/components/layout/sidebarComponents/AddAccountModal.vue';
import AccountSelector from 'dashboard/components/layout/sidebarComponents/AccountSelector.vue';
import AddLabelModal from 'dashboard/routes/dashboard/settings/labels/AddLabel.vue';
import NotificationPanel from 'dashboard/routes/dashboard/notifications/components/NotificationPanel.vue';
import UpgradePage from 'dashboard/routes/dashboard/upgrade/UpgradePage.vue';
import CopilotContainer from 'dashboard/components/copilot/CopilotContainer.vue';
import CopilotToggleButton from 'dashboard/components/copilot/CopilotToggleButton.vue';

import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAccount } from 'dashboard/composables/useAccount';

import wootConstants from 'dashboard/constants/globals';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { emitter } from 'shared/helpers/mitt';

const CommandBar = defineAsyncComponent(
  () => import('./commands/commandbar.vue')
);
const Sidebar = defineAsyncComponent(
  () => import('../../components/layout/Sidebar.vue')
);

const route = useRoute();

const upgradePageRef = ref(null);
const { uiSettings, updateUISettings } = useUISettings();
const { currentAccount } = useAccount();

const showAccountModal = ref(false);
const showCreateAccountModal = ref(false);
const showAddLabelModal = ref(false);
const showShortcutModal = ref(false);
const isNotificationPanel = ref(false);
const displayLayoutType = ref('');
const hasBanner = ref('');

const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const currentRoute = computed(() => ' ');

const showUpgradePage = computed(
  () => upgradePageRef.value?.shouldShowUpgradePage
);

const bypassUpgradePage = computed(() =>
  ['billing_settings_index', 'settings_inbox_list', 'agent_list'].includes(
    route.name
  )
);

const isSidebarOpen = computed(() => {
  const { show_secondary_sidebar: showSecondarySidebar } = uiSettings;
  return showSecondarySidebar;
});

const previouslyUsedDisplayType = computed(() => {
  const { previously_used_conversation_display_type: conversationDisplayType } =
    uiSettings;
  return conversationDisplayType;
});

const previouslyUsedSidebarView = computed(() => {
  const { previously_used_sidebar_view: showSecondarySidebar } = uiSettings;
  return showSecondarySidebar;
});

const showNextSidebar = computed(() =>
  isFeatureEnabledonAccount.value(
    currentAccount.value?.id,
    FEATURE_FLAGS.CHATWOOT_V4
  )
);

const checkBanner = () => {
  hasBanner.value = document.getElementsByClassName('woot-banner').length > 0;
};

const handleResize = () => {
  const { SMALL_SCREEN_BREAKPOINT, LAYOUT_TYPES } = wootConstants;
  let throttled = false;
  const delay = 150;

  if (throttled) return;
  throttled = true;

  setTimeout(() => {
    throttled = false;
    displayLayoutType.value =
      window.innerWidth <= SMALL_SCREEN_BREAKPOINT
        ? LAYOUT_TYPES.EXPANDED
        : LAYOUT_TYPES.CONDENSED;
  }, delay);
};

const toggleSidebar = () => {
  updateUISettings({
    show_secondary_sidebar: !isSidebarOpen.value,
    previously_used_sidebar_view: !isSidebarOpen.value,
  });
};

const openCreateAccountModal = () => {
  showAccountModal.value = false;
  showCreateAccountModal.value = true;
};

const closeCreateAccountModal = () => {
  showCreateAccountModal.value = false;
};

const toggleAccountModal = () => {
  showAccountModal.value = !showAccountModal.value;
};

const toggleKeyShortcutModal = () => {
  showShortcutModal.value = true;
};

const closeKeyShortcutModal = () => {
  showShortcutModal.value = false;
};

const showAddLabelPopup = () => {
  showAddLabelModal.value = true;
};

const hideAddLabelPopup = () => {
  showAddLabelModal.value = false;
};

const openNotificationPanel = () => {
  isNotificationPanel.value = true;
};

const closeNotificationPanel = () => {
  isNotificationPanel.value = false;
};

watch(displayLayoutType, () => {
  const { LAYOUT_TYPES } = wootConstants;
  updateUISettings({
    conversation_display_type:
      displayLayoutType.value === LAYOUT_TYPES.EXPANDED
        ? LAYOUT_TYPES.EXPANDED
        : previouslyUsedDisplayType.value,
    show_secondary_sidebar:
      displayLayoutType.value === LAYOUT_TYPES.EXPANDED
        ? false
        : previouslyUsedSidebarView.value,
  });
});

onMounted(() => {
  handleResize();
  nextTick(checkBanner);
  window.addEventListener('resize', handleResize);
  window.addEventListener('resize', checkBanner);
  emitter.on(BUS_EVENTS.TOGGLE_SIDEMENU, toggleSidebar);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
  window.removeEventListener('resize', checkBanner);
  emitter.off(BUS_EVENTS.TOGGLE_SIDEMENU, toggleSidebar);
});
</script>

<template>
  <div class="flex flex-wrap app-wrapper dark:text-slate-300">
    <NextSidebar
      v-if="showNextSidebar"
      @toggle-account-modal="toggleAccountModal"
      @open-key-shortcut-modal="toggleKeyShortcutModal"
      @close-key-shortcut-modal="closeKeyShortcutModal"
      @show-create-account-modal="openCreateAccountModal"
    />
    <Sidebar
      v-else
      :route="currentRoute"
      :has-banner="hasBanner"
      :show-secondary-sidebar="isSidebarOpen"
      @open-notification-panel="openNotificationPanel"
      @toggle-account-modal="toggleAccountModal"
      @open-key-shortcut-modal="toggleKeyShortcutModal"
      @close-key-shortcut-modal="closeKeyShortcutModal"
      @show-add-label-popup="showAddLabelPopup"
    />
    <main class="flex flex-1 h-full min-h-0 px-0 overflow-hidden">
      <UpgradePage
        v-show="showUpgradePage"
        ref="upgradePageRef"
        :bypass-upgrade-page="bypassUpgradePage"
      />
      <template v-if="!showUpgradePage">
        <router-view />
        <CopilotToggleButton />
        <CopilotContainer />
        <CommandBar />
        <NotificationPanel
          v-if="isNotificationPanel"
          @close="closeNotificationPanel"
        />
        <woot-modal
          v-model:show="showAddLabelModal"
          :on-close="hideAddLabelPopup"
        >
          <AddLabelModal @close="hideAddLabelPopup" />
        </woot-modal>
      </template>
      <AccountSelector
        :show-account-modal="showAccountModal"
        @close-account-modal="toggleAccountModal"
        @show-create-account-modal="openCreateAccountModal"
      />
      <AddAccountModal
        :show="showCreateAccountModal"
        @close-account-create-modal="closeCreateAccountModal"
      />
      <WootKeyShortcutModal
        v-model:show="showShortcutModal"
        @close="closeKeyShortcutModal"
        @clickaway="closeKeyShortcutModal"
      />
    </main>
  </div>
</template>
