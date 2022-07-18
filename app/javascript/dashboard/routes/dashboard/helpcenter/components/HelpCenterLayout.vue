<template>
  <div class="row app-wrapper">
    <sidebar
      :route="currentRoute"
      @open-notification-panel="openNotificationPanel"
      @open-key-shortcut-modal="toggleKeyShortcutModal"
      @close-key-shortcut-modal="closeKeyShortcutModal"
    />

    <!-- TO BE REPLACED WITH HELPCENTER SIDEBAR -->
    <div class="margin-right-small">
      {{ `Place the help center sidebar here.  ` }}
    </div>
    <!-- END: TO BE REPLACED WITH HELPCENTER SIDEBAR -->

    <section class="app-content columns">
      <router-view />
      <command-bar />
      <woot-key-shortcut-modal
        v-if="showShortcutModal"
        @close="closeKeyShortcutModal"
        @clickaway="closeKeyShortcutModal"
      />
      <notification-panel
        v-if="showNotificationPanel"
        @close="closeNotificationPanel"
      />
    </section>
  </div>
</template>
<script>
import Sidebar from 'dashboard/components/layout/Sidebar';
import CommandBar from 'dashboard/routes/dashboard/commands/commandbar.vue';
import WootKeyShortcutModal from 'dashboard/components/widgets/modal/WootKeyShortcutModal';
import NotificationPanel from 'dashboard/routes/dashboard/notifications/components/NotificationPanel.vue';

export default {
  components: {
    Sidebar,
    CommandBar,
    WootKeyShortcutModal,
    NotificationPanel,
  },
  data() {
    return {
      showShortcutModal: false,
      showNotificationPanel: false,
    };
  },
  computed: {
    currentRoute() {
      return ' ';
    },
  },
  methods: {
    toggleKeyShortcutModal() {
      this.showShortcutModal = true;
    },
    closeKeyShortcutModal() {
      this.showShortcutModal = false;
    },
    openNotificationPanel() {
      this.showNotificationPanel = true;
    },
    closeNotificationPanel() {
      this.showNotificationPanel = false;
    },
  },
};
</script>
