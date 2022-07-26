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
import { mapGetters } from 'vuex';

import { frontendURL } from '../../../../helper/URLHelper';
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
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
    // For testing
    accessibleMenuItems() {
      return [
        {
          icon: 'book',
          label: 'HELP_CENTER.ALL_ARTICLES',
          key: 'helpcenter_all',
          count: 199,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/:portalSlug/:locale/articles`
          ),
          toolTip: 'All Articles',
          toStateName: 'all_locale_articles',
        },
        {
          icon: 'pen',
          label: 'HELP_CENTER.MY_ARTICLES',
          key: 'helpcenter_mine',
          count: 112,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/:portalSlug/:locale/articles/mine`
          ),
          toolTip: 'My articles',
          toStateName: 'mine_articles',
        },
        {
          icon: 'draft',
          label: 'HELP_CENTER.DRAFT',
          key: 'helpcenter_draft',
          count: 32,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/:portalSlug/:locale/articles/draft`
          ),
          toolTip: 'Draft',
          toStateName: 'draft_articles',
        },
        {
          icon: 'archive',
          label: 'HELP_CENTER.ARCHIVED',
          key: 'helpcenter_archive',
          count: 10,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/:portalSlug/:locale/articles/archived`
          ),
          toolTip: 'Archived',
          toStateName: 'archived_articles',
        },
      ];
    },
    additionalSecondaryMenuItems() {
      return [
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
              toState: frontendURL(
                `accounts/${this.accountId}/portals/:portalSlug/:locale/categories/getting-started`
              ),
            },
            {
              id: 2,
              label: 'Channel',
              count: 19,
              truncateLabel: true,
              toState: frontendURL(
                `accounts/${this.accountId}/portals/:portalSlug/:locale/categories/channel`
              ),
            },
            {
              id: 3,
              label: 'Feature',
              count: 24,
              truncateLabel: true,
              toState: frontendURL(
                `accounts/${this.accountId}/portals/:portalSlug/:locale/categories/feature`
              ),
            },
            {
              id: 4,
              label: 'Advanced',
              count: 8,
              truncateLabel: true,
              toState: frontendURL(
                `accounts/${this.accountId}/portals/:portalSlug/:locale/categories/advanced`
              ),
            },
            {
              id: 5,
              label: 'Mobile app',
              count: 3,
              truncateLabel: true,
              toState: frontendURL(
                `accounts/${this.accountId}/portals/:portalSlug/:locale/categories/mobile-app`
              ),
            },
            {
              id: 6,
              label: 'Others',
              count: 39,
              truncateLabel: true,
              toState: frontendURL(
                `accounts/${this.accountId}/portals/:portalSlug/:locale/categories/others`
              ),
            },
          ],
        },
      ];
    },
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
