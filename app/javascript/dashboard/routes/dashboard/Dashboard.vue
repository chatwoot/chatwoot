<script>
import { defineAsyncComponent, ref } from 'vue';

import NextSidebar from 'next/sidebar/Sidebar.vue';
import WootKeyShortcutModal from 'dashboard/components/widgets/modal/WootKeyShortcutModal.vue';
import AddAccountModal from 'dashboard/components/app/AddAccountModal.vue';
import UpgradePage from 'dashboard/routes/dashboard/upgrade/UpgradePage.vue';

import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAccount } from 'dashboard/composables/useAccount';

import wootConstants from 'dashboard/constants/globals';

const CommandBar = defineAsyncComponent(
  () => import('./commands/commandbar.vue')
);

import CopilotLauncher from 'dashboard/components-next/copilot/CopilotLauncher.vue';
import CopilotContainer from 'dashboard/components/copilot/CopilotContainer.vue';

import MobileSidebarLauncher from 'dashboard/components-next/sidebar/MobileSidebarLauncher.vue';

export default {
  components: {
    NextSidebar,
    CommandBar,
    WootKeyShortcutModal,
    AddAccountModal,
    UpgradePage,
    CopilotLauncher,
    CopilotContainer,
    MobileSidebarLauncher,
  },
  setup() {
    const upgradePageRef = ref(null);
    const { uiSettings, updateUISettings } = useUISettings();
    const { accountId } = useAccount();

    return {
      uiSettings,
      updateUISettings,
      accountId,
      upgradePageRef,
    };
  },
  data() {
    return {
      showAccountModal: false,
      showCreateAccountModal: false,
      showShortcutModal: false,
      displayLayoutType: '',
      isMobileSidebarOpen: false,
    };
  },
  computed: {
    showUpgradePage() {
      return this.upgradePageRef?.shouldShowUpgradePage;
    },
    bypassUpgradePage() {
      return [
        'billing_settings_index',
        'settings_inbox_list',
        'general_settings_index',
        'agent_list',
      ].includes(this.$route.name);
    },
    previouslyUsedDisplayType() {
      const {
        previously_used_conversation_display_type: conversationDisplayType,
      } = this.uiSettings;
      return conversationDisplayType;
    },
    previouslyUsedSidebarView() {
      const { previously_used_sidebar_view: showSecondarySidebar } =
        this.uiSettings;
      return showSecondarySidebar;
    },
  },
  watch: {
    displayLayoutType() {
      const { LAYOUT_TYPES } = wootConstants;
      this.updateUISettings({
        conversation_display_type:
          this.displayLayoutType === LAYOUT_TYPES.EXPANDED
            ? LAYOUT_TYPES.EXPANDED
            : this.previouslyUsedDisplayType,
        show_secondary_sidebar:
          this.displayLayoutType === LAYOUT_TYPES.EXPANDED
            ? false
            : this.previouslyUsedSidebarView,
      });
    },
  },
  mounted() {
    this.handleResize();
    window.addEventListener('resize', this.handleResize);
  },
  unmounted() {
    window.removeEventListener('resize', this.handleResize);
  },

  methods: {
    handleResize() {
      const { SMALL_SCREEN_BREAKPOINT, LAYOUT_TYPES } = wootConstants;
      let throttled = false;
      const delay = 150;

      if (throttled) {
        return;
      }
      throttled = true;

      setTimeout(() => {
        throttled = false;
        if (window.innerWidth <= SMALL_SCREEN_BREAKPOINT) {
          this.displayLayoutType = LAYOUT_TYPES.EXPANDED;
        } else {
          this.displayLayoutType = LAYOUT_TYPES.CONDENSED;
        }
      }, delay);
    },
    toggleMobileSidebar() {
      this.isMobileSidebarOpen = !this.isMobileSidebarOpen;
    },
    closeMobileSidebar() {
      this.isMobileSidebarOpen = false;
    },
    openCreateAccountModal() {
      this.showAccountModal = false;
      this.showCreateAccountModal = true;
    },
    closeCreateAccountModal() {
      this.showCreateAccountModal = false;
    },
    toggleAccountModal() {
      this.showAccountModal = !this.showAccountModal;
    },
    toggleKeyShortcutModal() {
      this.showShortcutModal = true;
    },
    closeKeyShortcutModal() {
      this.showShortcutModal = false;
    },
  },
};
</script>

<template>
  <div class="relative flex flex-grow overflow-hidden text-n-slate-12">
    <NextSidebar
      :is-mobile-sidebar-open="isMobileSidebarOpen"
      @toggle-account-modal="toggleAccountModal"
      @open-key-shortcut-modal="toggleKeyShortcutModal"
      @close-key-shortcut-modal="closeKeyShortcutModal"
      @show-create-account-modal="openCreateAccountModal"
      @close-mobile-sidebar="closeMobileSidebar"
    />

    <main class="flex flex-1 h-full w-full min-h-0 px-0 overflow-hidden">
      <template v-if="!showUpgradePage">
        <router-view />
        <CommandBar />
        <CopilotLauncher />
        <MobileSidebarLauncher
          :is-mobile-sidebar-open="isMobileSidebarOpen"
          @toggle="toggleMobileSidebar"
        />
        <CopilotContainer />
      </template>
      <UpgradePage
        v-else
        ref="upgradePageRef"
        :bypass-upgrade-page="bypassUpgradePage"
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
