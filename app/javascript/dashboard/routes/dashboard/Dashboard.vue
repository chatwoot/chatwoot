<template>
  <div class="row app-wrapper">
    <sidebar
      :route="currentRoute"
      :show-secondary-sidebar="isSidebarOpen"
      @open-notification-panel="openNotificationPanel"
      @toggle-account-modal="toggleAccountModal"
      @open-key-shortcut-modal="toggleKeyShortcutModal"
      @close-key-shortcut-modal="closeKeyShortcutModal"
      @show-add-label-popup="showAddLabelPopup"
    />
    <section class="app-content columns">
      <router-view />
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
        :show.sync="showShortcutModal"
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
import AddLabelModal from 'dashboard/routes/dashboard/settings/labels/AddLabel';
import NotificationPanel from 'dashboard/routes/dashboard/notifications/components/NotificationPanel';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';

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
  mixins: [uiSettingsMixin],
  data() {
    return {
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
    isSidebarOpen() {
      const { show_secondary_sidebar: showSecondarySidebar } = this.uiSettings;
      return showSecondarySidebar;
    },
  },
  mounted() {
    bus.$on(BUS_EVENTS.TOGGLE_SIDEMENU, this.toggleSidebar);
  },
  beforeDestroy() {
    bus.$off(BUS_EVENTS.TOGGLE_SIDEMENU, this.toggleSidebar);
  },
  methods: {
    toggleSidebar() {
      this.updateUISettings({
        show_secondary_sidebar: !this.isSidebarOpen,
      });
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
