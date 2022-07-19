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
      <help-center-sidebar
        header-title="Help Center"
        sub-title="English"
        :accessible-menu-items="accessibleMenuItems"
        :additional-secondary-menu-items="additionalSecondaryMenuItems"
      />
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
import HelpCenterSidebar from 'dashboard/components/helpCenter/Sidebar/Sidebar';
import CommandBar from 'dashboard/routes/dashboard/commands/commandbar.vue';
import WootKeyShortcutModal from 'dashboard/components/widgets/modal/WootKeyShortcutModal';
import NotificationPanel from 'dashboard/routes/dashboard/notifications/components/NotificationPanel.vue';

export default {
  components: {
    Sidebar,
    HelpCenterSidebar,
    CommandBar,
    WootKeyShortcutModal,
    NotificationPanel,
  },
  data() {
    return {
      showShortcutModal: false,
      showNotificationPanel: false,

      // For testing purposes
      accessibleMenuItems: [
        {
          icon: 'book',
          label: 'HELP_CENTER.ALL_ARTICLES',
          key: 'helpcenter_all',
          count: 199,
          toState: '/app/accounts/3/portals',
          toolTip: 'All Articles',
          toStateName: 'helpcenter_all',
        },
        {
          icon: 'pen',
          label: 'HELP_CENTER.MY_ARTICLES',
          key: 'helpcenter_mine',
          count: 112,
          toState: 'accounts/1/articles/mine',
          toolTip: 'My articles',
          toStateName: 'helpcenter_mine',
        },
        {
          icon: 'draft',
          label: 'HELP_CENTER.DRAFT',
          key: 'helpcenter_draft',
          count: 32,
          toState: 'accounts/1/articles/draft',
          toolTip: 'Draft',
          toStateName: 'helpcenter_draft',
        },
        {
          icon: 'archive',
          label: 'HELP_CENTER.ARCHIVED',
          key: 'helpcenter_archive',
          count: 10,
          toState: 'accounts/1/articles/archived',
          toolTip: 'Archived',
          toStateName: 'helpcenter_archive',
        },
      ],
      additionalSecondaryMenuItems: [
        {
          icon: 'folder',
          label: 'HELP_CENTER.CATEGORY',
          hasSubMenu: true,
          key: 'category',
          children: [
            {
              id: 1,
              label: 'Getting started',
              count: 12,
              truncateLabel: true,
              toState: 'accounts/1/articles/categories/new',
            },
            {
              id: 2,
              label: 'Channel',
              count: 19,
              truncateLabel: true,
              toState: 'accounts/1/articles/categories/channel',
            },
            {
              id: 3,
              label: 'Feature',
              count: 24,
              truncateLabel: true,
              toState: 'accounts/1/articles/categories/feature',
            },
            {
              id: 4,
              label: 'Advanced',
              count: 8,
              truncateLabel: true,
              toState: 'accounts/1/articles/categories/advanced',
            },
            {
              id: 5,
              label: 'Mobile app',
              count: 3,
              truncateLabel: true,
              toState: 'accounts/1/articles/categories/mobile-app',
            },
            {
              id: 6,
              label: 'Others',
              count: 39,
              truncateLabel: true,
              toState: 'accounts/1/articles/categories/others',
            },
          ],
        },
      ],
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
