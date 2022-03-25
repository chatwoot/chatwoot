<template>
  <div class="row app-wrapper">
    <sidebar
      :route="currentRoute"
      :class="sidebarClassName"
      @open-notification-panel="openNotificationPanel"
      @toggle-account-modal="toggleAccountModal"
      @open-key-shortcut-modal="toggleKeyShortcutModal"
      @close-key-shortcut-modal="closeKeyShortcutModal"
      @show-add-label-popup="showAddLabelPopup"
    ></sidebar>
    <section class="app-content columns" :class="contentClassName">
      <router-view></router-view>
      <command-bar />
      <account-selector
        :show-account-modal="showAccountModal"
        @close-account-modal="toggleAccountModal"
        @show-create-account-modal="openCreateAccountModal"
      />
      <add-account-modal
        :show="showCreateAccountModal"
        @close-account-create-modal="closeCreateAccountModal"
      />
      <woot-key-shortcut-modal
        v-if="showShortcutModal"
        @close="closeKeyShortcutModal"
        @clickaway="closeKeyShortcutModal"
      />
      <notification-panel
        v-if="isNotificationPanel"
        @close="closeNotificationPanel"
      />
      <woot-modal :show.sync="showAddLabelModal" :on-close="hideAddLabelPopup">
        <add-label-modal @close="hideAddLabelPopup" />
      </woot-modal>
    </section>
  </div>
</template>

<script>
import Sidebar from '../../components/layout/Sidebar';
import CommandBar from './commands/commandbar.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import WootKeyShortcutModal from 'dashboard/components/widgets/modal/WootKeyShortcutModal';
import AddAccountModal from 'dashboard/components/layout/sidebarComponents/AddAccountModal';
import AccountSelector from 'dashboard/components/layout/sidebarComponents/AccountSelector';
import AddLabelModal from 'dashboard/routes/dashboard/settings/labels/AddLabel.vue';
import NotificationPanel from 'dashboard/routes/dashboard/notifications/components/NotificationPanel.vue';

export default {
  components: {
    Sidebar,
    CommandBar,
    WootKeyShortcutModal,
    AddAccountModal,
    AccountSelector,
    AddLabelModal,
    NotificationPanel,
  },
  data() {
    return {
      isSidebarOpen: false,
      isOnDesktop: true,
      showAccountModal: false,
      showCreateAccountModal: false,
      showAddLabelModal: false,
      showShortcutModal: false,
      isNotificationPanel: false,
    };
  },
  computed: {
    currentRoute() {
      return ' ';
    },
    sidebarClassName() {
      if (this.isOnDesktop) {
        return '';
      }
      if (this.isSidebarOpen) {
        return 'off-canvas position-left is-transition-push is-open';
      }
      return 'off-canvas is-transition-push is-closed';
    },
    contentClassName() {
      if (this.isOnDesktop) {
        return '';
      }
      if (this.isSidebarOpen) {
        return 'off-canvas-content is-open-left has-transition-push has-position-left';
      }
      return 'off-canvas-content has-transition-push';
    },
  },
  mounted() {
    this.$store.dispatch('setCurrentAccountId', this.$route.params.accountId);
    window.addEventListener('resize', this.handleResize);
    this.handleResize();
    bus.$on(BUS_EVENTS.TOGGLE_SIDEMENU, this.toggleSidebar);
  },
  beforeDestroy() {
    bus.$off(BUS_EVENTS.TOGGLE_SIDEMENU, this.toggleSidebar);
    window.removeEventListener('resize', this.handleResize);
  },
  methods: {
    handleResize() {
      if (window.innerWidth > 1200) {
        this.isOnDesktop = true;
      } else {
        this.isOnDesktop = false;
      }
    },
    toggleSidebar() {
      this.isSidebarOpen = !this.isSidebarOpen;
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
    showAddLabelPopup() {
      this.showAddLabelModal = true;
    },
    hideAddLabelPopup() {
      this.showAddLabelModal = false;
    },
    openNotificationPanel() {
      this.isNotificationPanel = true;
    },
    closeNotificationPanel() {
      this.isNotificationPanel = false;
    },
  },
};
</script>
<style lang="scss" scoped>
.off-canvas-content.is-open-left {
  transform: translateX(25.4rem);
}
</style>
